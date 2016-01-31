class SeedForStatistics
  # require 'csv'

  # def initialize statistic_data
  #   @trackers       = Tracker.joins(:affiliate)
  #   @count_trackers = @trackers.count
  #   @data           = statistic_data.blank? ? default_data_for_create : statistic_data
  # end

  # def default_data_for_create
  #   start_date, end_date = [:beginning_of_month, :end_of_month].map { |k| Date.today.send(k) }
  #   s_start_date, s_end_date = [start_date, end_date].map{ |d| d.strftime('%d_%m_%Y') }
  #   res = (start_date..end_date).inject({}) do |res, date|
  #     s_date, f_date = date.to_s, date.strftime('%d_%m_%Y')
  #     dps = gen_dps_csv(s_date)
  #     res.merge(
  #               "daily_players_statistics-#{f_date}" => dps,
  #               "daily_statistics_players-#{f_date}" => gen_dsp_csv(dps)
  #              )
  #   end
  #   mps = gen_mps_csv(res.select{|k,v| k =~ /daily_players_statistics/})
  #   res.merge("monthly_palyers_statistics-#{s_start_date}-#{s_end_date}" => mps)
  # end

  # def gen_dps_csv date
  #   CSV.generate do |csv|
  #     csv << [
  #             :transaction_date, :customer_id, :player_id, :serial_id, :acid, :deposits, :approved_net_deposits,
  #             :bankroll, :poker_bets, :poker_rake, :poker_tournament_fees, :poker_bonus, :poker_netwin,
  #             :poker_sharecost_bonus, :poker_fullcost_bonus, :granted_trt, :granted_immediate_bonus, :removed_bonuses,
  #             :casino_bets, :casino_revenue, :casino_stake, :isftd, :ismoneytransfe, :player_status
  #            ]
  #     rand(100).times do |i|
  #       csv << [
  #               date, (DateTime.now.to_i + rand(100)).to_s[0..8], "player_#{i}", @trackers[rand(@count_trackers)].tracker_code, -1, rand(100), rand(-100..100),
  #               rand(0..100.0).round(2), rand(5000), rand(0..500.0).round(2), rand(0..500.0).round(2), rand(100), rand(-500..500.0).round(2),
  #               rand(100), rand(100), rand(10), rand(100), 0,
  #               0, 0, 0, 1, rand(2), 1
  #              ]
  #     end
  #   end
  # end

  # def gen_dsp_csv dps
  #   dps = CSV.parse(dps)
  #   dps.shift
  #   countries = ['Russia', 'Ukraine']
  #   CSV.generate do |csv|
  #     csv << [:account_opening_date, :serial_id, :acid, :customer_id, :player_id, :player_country]
  #     dps.each do |r|
  #       csv << [r[0], r[3], r[4], r[1], r[2], countries[rand(countries.count)]]
  #     end
  #   end
  # end

  # def gen_mps_csv monthly_dps
  #   mdps = monthly_dps.map{ |dps| a=CSV.parse(dps.last); a.shift; a }.flatten(1)
  #   CSV.generate do |csv|
  #     csv << [
  #             :transaction_date, :player_id, :serial_id, :acid, :deposits, :general_deductions,
  #             :general_bonuses, :games_bets, :games_revenue, :games_stake, :games_bonus, :poker_bets,
  #             :poker_rake, :poker_tournament_fees, :poker_stake, :poker_bonus, :casino_bets, :casino_revenue,
  #             :casino_stake, :casino_bonus, :sportsbook_bets, :sportsbook_revenue, :sportsbook_stake,
  #             :sportsbook_bonus, :player_status, :isftd, :ismoneytransfe
  #            ]
  #     mdps.each do |r|
  #       csv << [
  #               r[0], r[2], r[3], r[4], r[5], rand(0..100.0).round(2),
  #               rand(-500..500.0).round(2), 0, 0, 0, 0, r[8],
  #               r[9], r[10], rand(0..5000.0).round(2), r[11], r[18], r[19],
  #               r[20], 0, 0, 0, 0,
  #               0, r[23], r[21], r[22]
  #              ]
  #     end
  #   end
  # end

  # def create
  #   FtpFile.parse_ftp_file @data
  #   ColorText.set_color("DailyPlayersStatistic", DailyPlayersStatistic.all.to_a)
  #   ColorText.set_color("DailyStatisticsPlayer", DailyStatisticsPlayer.all.to_a)
  #   ColorText.set_color("MonthlyPalyersStatistic", MonthlyPalyersStatistic.all.to_a)
  # end

  # def self.create statistic_data=nil
  #   new(statistic_data).create
  # end
end