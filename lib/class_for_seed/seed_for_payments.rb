class SeedForPayments

  def initialize user_data
    @data = user_data.blank? ? default_data_for_create : user_data
  end

  def default_data_for_create
    ['Skrill', 'Webmoney'].map do |v|
      {
        name: v,
        active: true
      }
    end
  end

  def create
    ActiveRecord::Base.transaction do
      @payments = @data.map { |p| Payment.create(p) }.reject { |p| p.id.nil? }
      ColorText.set_color("Payments", @payments)
    end
  end

  def self.create data=nil
    new(data).create
  end
end
