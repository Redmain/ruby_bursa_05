namespace :data do
  desc 'autopilot'
  task autopilot: :environment do
    begin
      Rake::Task["data:loading"].invoke

      jid = Rails.cache.read('FtpFileWorkerJid')

      until Sidekiq::Status::complete?(jid)
        if Sidekiq::Status::failed?(jid)
          return
        end
        sleep 10
      end if jid

      Rails.cache.delete('FtpFileWorkerJid')

      create_dump('before_find_lost_trackers')
      Rake::Task["data:find_lost_trackers"].invoke

      create_dump('before_correction')
      Rake::Task["data:correction"].invoke

      create_dump('before_load_player_achievements')
      Rake::Task["data:load_player_achievements"].invoke

      create_dump('before_load_affiliate_payments')
      Rake::Task["data:load_affiliate_payments"].invoke

      create_dump('before_refresh_view_worker')
      jid = RefreshViewWorker.perform_async
      until Sidekiq::Status::complete?(jid)
        if Sidekiq::Status::failed?(jid)
          return
        end
        sleep 10
      end if jid

      create_dump('before_processing_daily_data_worker')
      SidekiqMaster.perform_async('ProcessingDailyDataWorker')

    rescue Exception => e
      File.open(Rails.root.join('log', 'autopilot_errors.log'), 'a+') do |f|
        f.puts e.message
        f.puts e.backtrace.inspect
        f.puts '=' * 100
      end
    end
  end

  desc "Loading data in database"
  task :loading => :environment do

    t_start = Time.now

    Rake::Task["db:migrate:reset"].invoke

    manager = SeedForManagers.create(
                [
                  {
                    name: 'Test manager',
                    email: 'manager_test@gmail.com',
                  }.merge(RunSeed::PASSWORD)
                ]
              ).first

    admin = SeedForAdmins.create(
              [
                {
                  name: 'Test admin',
                  email: 'admin_test@gmail.com',
                }.merge(RunSeed::PASSWORD)
              ]
            ).first

    payment_system = SeedForPayments.create([{ name: 'Webmoney', active: true }]).first

    conditions = SeedForConditions.create([{
                                            title: "Test condition CPA",
                                            description: "Test condition CPA",
                                            type_of_transaction: Condition::TYPE_OF_TRANSACTION['CPA'],
                                            additional_condition: 'none'
                                          }])
    condition_items = SeedForConditionItems.create(conditions,
      {
        conditions.first.id => {
          "ggr" => {
            :obtained_result => "ggr",
            :condition_for_comparison => ">=",
            :desired_value => 10
          },
          "deposits" => {
            :obtained_result => "deposits",
            :condition_for_comparison => ">=",
            :desired_value => 10
          }
        }
      }
    )
    condition_steps = SeedForConditionSteps.create(conditions,
      {
        'basic' => [{
          condition_type: 'basic',
          payment_size: 60
        }]
      }
    )
    # condition_step_items = SeedForConditionStepItems.create(condition_steps, options.delete(:condition_step_items_data))

    aff_serial = CSV.read(
                            'ftp_files/aff-serial-v3.csv',
                            headers: true,
                            header_converters: :symbol,
                            converters: [:all],
                            col_sep: "\t"
                          )

    unless aff_serial.blank?
      trackers =  SeedForTrackers.create(
                    aff_serial.map do |as|
                      {
                        tracker_code: as[:serial_id],
                        assigning_at: DateTime.now,
                        description:  as[:site_name],
                        name:         as[:site_id]
                      }
                    end
                  )
      trackers.map(&:assigning!)
    end

    ActiveRecord::Base.transaction do
      aff_serial.group_by { |x| x[:email_address] }.each do |a|
        q = a.last.first
        password = 10.times.map { ['a'..'z', 'A'..'Z', '0'..'9'].map{ |q| q.to_a.sample } }.join
        date = DateTime.now
        affiliate = Affiliate.new({
                                    email:              q[:email_address],
                                    confirmed_at:       date,
                                    name:               Russian.translit([:first_name, :last_name].map{ |k| q[k] }.join(' ')),
                                    birthday:           date,
                                    skype:              "Not.Set",
                                    phone_number:       "79000000000",
                                    site_url:           "htpp://lotosq.com/",
                                    about_affiliate:    "          ",
                                    payment_system:     payment_system.name,
                                    account_number:     "Z000000000000",
                                    decision_time:      date,
                                    country:            q[:country],
                                    username:           q[:username],
                                    accept_the_license: '1',
                                    sign_in_count: 1
                                  }.merge(password: password, password_confirmation: password, chief: manager))
        affiliate.save
        Tracker.where(tracker_code: a.last.map { |t| t[:serial_id] }.compact ).update_all(affiliate_id: affiliate.id)
        affiliate.approve!
      end
    end
    print_result ("Done. Created #{Affiliate.count} records")
    print_result ("Done. Аound #{Tracker.where.not(affiliate_id: nil).count} matching")

    aff_serial = nil

    aff_state = CSV.read(
                          'ftp_files/inactive_affiliate.csv',
                          headers: true,
                          header_converters: :symbol,
                          converters: [:all],
                          col_sep: "\t"
                        )
    aff_state.each do |as|
      a = Affiliate.find_by(email: as[:email_address])
      if a && URI.regexp =~ as[:website_url]
        a.site_url = as[:website_url]
        a.save
        if as[:networkstatus] == 'Inactive'
          a.change_ban_status!(manager)
        end
      end
    end

    FtpFile.create(
      [
        'daily_players_statistics-01_01_2011',
        'daily_players_statistics-01_01_2012',
        'daily_players_statistics-01_01_2013',
        'daily_players_statistics-01_01_2014',
        'daily_players_statistics-01_01_2015',
        'daily_players_statistics-02_01_2015',
        'daily_statistics_players-01_01_2015',
        'daily_statistics_players-02_01_2015'
      ].map { |e| { name: e } }
    )

    create_dump 'before_ftp_file_worker'

    jid = SidekiqMaster.perform_async('FtpFileWorker')

    Rails.cache.write('FtpFileWorkerJid', jid)

    t_end = Time.now
    print_result ("#{t_end - t_start}.sec")
  end

  desc "Find lost trackers"
  task :find_lost_trackers => :environment do

    data = DailyStatisticsPlayer.all.map do |dsp|
                    {
                      tracker_code: dsp.serial_id,
                      assigning_at: DateTime.now
                    }
                  end
    unless data.blank?
      trackers =  SeedForTrackers.create(data)
      trackers.map(&:assigning!)
    end

    ActiveRecord::Base.transaction do
      password = 10.times.map { ['a'..'z', 'A'..'Z', '0'..'9'].map{ |q| q.to_a.sample } }.join
      date = DateTime.now
      manager = Manager.find_by(email: 'manager_test@gmail.com')
      affiliate = Affiliate.new({
                                  email:              'lotos_marketing@gmail.com',
                                  confirmed_at:       date,
                                  name:               'Lotos Marketing',
                                  birthday:           date,
                                  skype:              "Not.Set",
                                  phone_number:       "79000000000",
                                  site_url:           "htpp://lotosq.com/",
                                  about_affiliate:    "          ",
                                  payment_system:     'Webmoney',
                                  account_number:     "Z000000000000",
                                  decision_time:      date,
                                  country:            'Russian',
                                  username:           'Lotos',
                                  accept_the_license: '1',
                                  sign_in_count: 1
                                }.merge(password: password, password_confirmation: password, chief: manager))
      affiliate.approve
      affiliate.save
      Tracker.assigned.where(affiliate_id: nil).update_all(affiliate_id: affiliate.id)
    end
  end

  desc "Correction data in database"
  task :correction => :environment do
    logger  = Logger.new('log/correction_of_data.log')
    t_start = Time.now
    logger.info("Start at: #{t_start}")
    DailyPlayersStatistic.find_in_batches do |dps_g|
      ActiveRecord::Base.transaction do
        dps_g.each do |dps|
          sharecost_bonus = dps.sharecost_bonus - dps.converted_bonus_points
          if dps.bonuses == dps.fullcost_bonus + sharecost_bonus + dps.converted_bonus_points + dps.jp_adjsutments
            dps.update(sharecost_bonus: sharecost_bonus)
          else
            logger.error ("id: #{dps.id}")
            print_result ("Error!!! id: #{dps.id}")
          end
        end
      end
    end
    t_end = Time.now
    logger.info("End at: #{t_end}")
    logger.info("Executed at: #{t_end - t_start}.sec")
  end

  desc "Load player achievements"
  task :load_player_achievements => :environment do

    affiliates = Set.new

    [
      '2011_CPA_report', '2012_CPA_report', '2013_CPA_report',
      '2014_CPA_report', '2015_CPA_report'
    ].each do |f|
      date = Date.strptime(f, '%Y')
      cpa_reports = CSV.read(
                              "ftp_files/#{f}.csv",
                              headers: true,
                              header_converters: :symbol,
                              converters: [:all],
                              col_sep: "\t"
                            )
      cpa_reports.each do |cr|
        dsp = DailyStatisticsPlayer.find_by(cid: cr[:player_id])
        if cr[:cpa_count] > 0 && !dsp.blank?
          tracker = dsp.tracker
          affiliate = tracker.affiliate
          Achievement.create(
            tracker_id: tracker.id,
            username: dsp.username,
            cid: dsp.cid,
            anid: dsp.anid,
            date_of_completion: date,
            execution_condition: 'none',
            type_of_transaction: 'none'
          )
          affiliates << affiliate
        end
      end
    end
    ProcessingDailyDataWorker.new.write_processing_daily_data_worker_affiliates affiliates
  end

  desc "Load affiliate payments"
  task :load_affiliate_payments => :environment do

    affiliates = Set.new

    [
      '2011_Aff_report', '2012_Aff_report', '2013_Aff_report',
      '2014_Aff_report', '2015_Aff_report'
    ].each do |f|
      aff_reports = CSV.read(
                              "ftp_files/#{f}.csv",
                              headers: true,
                              header_converters: :symbol,
                              converters: [:all],
                              col_sep: "\t"
                            )

      aff_reports.select do |ar|
                    ar[:rowid] == 1
                  end.group_by do |ar|
                    [
                      ar[:username],
                      Date.strptime(ar[:period], '%d/%m/%Y').end_of_month,
                      ar[:serial_id]
                    ].join('_')
                  end.each do |_, ars|

                    ar = ars.first
                    affiliate = Affiliate.find_by(username: ar[:username])
                    tracker = Tracker.find_by(tracker_code: ar[:serial_id])
                    date_of_payment = Date.strptime(ar[:period], '%d/%m/%Y').end_of_month rescue nil

                    next unless [affiliate, tracker, date_of_payment].all?

                    data = { profit: ars.sum{ |a| a[:_commission] + a[:cpa_commission] } }

                    ap =  AffiliatePayment.where({
                                  affiliate_id: affiliate.id,
                                  tracker_id: tracker.id,
                                  date_of_payment: date_of_payment
                                }).first_or_initialize
                    if ap.new_record?
                      ap.attributes = data
                      ap.save
                      affiliates << affiliate
                    end
                  end
    end
    ProcessingDailyDataWorker.new.write_processing_daily_data_worker_affiliates affiliates
  end

  desc "load_conditions_for_trackers"
  task load_conditions_for_trackers: :environment do
    conditions_for_trackers = CSV.read(
                                "ftp_files/conditions_for_trackers.csv",
                                headers: true,
                                header_converters: :symbol,
                                converters: [:all],
                                col_sep: "\t"
                              )
    conditions_for_trackers.each do |cft|
      condition = Condition.find_by(title: cft[:deal_name])
      tracker = Tracker.where(tracker_code: cft[:serial])
      if !tracker.blank?
        tracker.update_all(condition_id: condition.id)
      else
        puts "Такого трекера нет #{cft[:serial]}"
      end
    end
  end

  desc "change_players_serial"
  task change_players_serial: :environment do
    change_players_serial = CSV.read(
                              "ftp_files/change_players_serial.csv",
                              headers: true,
                              header_converters: :symbol,
                              converters: [:all],
                              col_sep: "\t"
                            )
    admin = Admin.find_by(email: 'roman@lotosaffiliates.com')
    change_players_serial.each do |cps|
      dsp = DailyStatisticsPlayer.find_by(cid: cps[:cid])
      tracker = Tracker.find_by(tracker_code: cps[:new_serial])
      if [dsp, tracker].all? && dsp.serial_id != tracker.tracker_code
        history_of_players_change_params = {
          anid: dsp.current_anid,
          creator: admin,
          serial_id: cps[:new_serial],
          date: cps[:activation_date]
        }
        d = dsp.history_of_players_changes.new(history_of_players_change_params)
        unless d.save
          puts d.errors.to_a
        end
      else
        puts "Такого трекера нет #{cps[:serial]}" unless tracker
        puts "Такого cid нет #{cps[:cid]}" unless dsp
        puts "Такой трекер уже установлен #{cps[:cid]}" if [dsp, tracker].all? && dsp.serial_id == tracker.tracker_code
      end
    end
  end
end

def print_result text
  puts "\033[#{[95, 91, 35, 34, 33, 32, 31].sample}m\033[4m#{text}\033[0m"
end

def create_dump comment
  system("pg_dump -Urails quintessence_prod --no-owner > /var/www/quintessence/dumps/dump_#{comment}_#{Time.now.strftime('%d_%m_%Y_%H_%M_%S')}.sql")
end
