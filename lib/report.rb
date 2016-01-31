class Report

  PER_PAGE = [20, 50, 100, 500, 1000]

  include ActiveModel::Model

  attr_writer :serial_id, :affiliate_name, :per_page, :daily_statistics_player_username,
              :daily_statistics_player_cid, :selected_columns

  attr_accessor :period

  def serial_id
    @serial_id.try{ delete_if(&:blank?) } || []
  end

  def affiliate_name
    @affiliate_name.try{ delete_if(&:blank?) } || []
  end

  def daily_statistics_player_username
    @daily_statistics_player_username.try{ delete_if(&:blank?) } || []
  end

  def daily_statistics_player_cid
    @daily_statistics_player_cid.try{ delete_if(&:blank?) } || []
  end

  def selected_columns
    @selected_columns.try{ delete_if(&:blank?) }.try!{ |e| e if e.present? }
  end

  def get_daily_statistics_player_username
    @daily_statistics_player_username.try(:first).try{ split(';').delete_if(&:blank?) } || []
  end

  def get_daily_statistics_player_cid
    @daily_statistics_player_cid.try(:first).try{ split(';').delete_if(&:blank?) } || []
  end

  def get_period
    period = JSON.parse(@period) unless @period.blank?
    period ? period['start']..period['end'] : Affiliate.period_in_hash[1]
  end

  def per_page
    @per_page.blank? ? 20 : @per_page
  end

  def calculate_padding(permit_columns)
    permit_columns.inject(0) do |res, c|
      res += case c
              when 'affiliate_name', 'affiliate_username', 'affiliate_payment_system'
                self.affiliate_name.present?
              when 'serial_id', 'tracker_description'
                [
                  self.serial_id,
                  self.get_daily_statistics_player_username,
                  self.get_daily_statistics_player_cid
                ].map(&:present?).any?
              when 'transaction_date'
                self.by_day
              when 'an_id'
                self.by_anid
              when 'username', 'cid'
                self.by_user
              end ? 1 : 0
    end
  end

  def by_day
    self.selected_columns.include?('transaction_date')
  end

  def by_anid
    self.selected_columns.include?('an_id')
  end

  def by_user
    self.selected_columns.any? { |sc| ['username', 'cid'].include?(sc) }
  end

  def by_affiliate_name
    self.selected_columns.any? { |sc| ['affiliate_username', 'affiliate_name'].include?(sc) } && self.affiliate_name.present?
  end

  def by_serial
    self.selected_columns
        .any? do |sc|
          ['serial_id', 'tracker_description'].include?(sc)
        end &&  [
                  self.serial_id,
                  self.get_daily_statistics_player_username,
                  self.get_daily_statistics_player_cid
                ].map(&:present?).any?
  end

  def formation_query
    affiliate_name = 'result.affiliate_name, result.affiliate_username, result.affiliate_payment_system' if self.by_affiliate_name
    by_day         = 'result.transaction_date' if self.by_day
    by_serial      = '(result.serial_id)::int, result.tracker_description' if self.by_serial
    by_anid        = 'result.an_id' if self.by_anid
    by_user        = 'result.username, result.cid' if self.by_user
    [affiliate_name, by_day, by_serial, by_anid, by_user].delete_if(&:blank?).join(', ')
  end
end
