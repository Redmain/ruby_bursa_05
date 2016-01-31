class SeedForAffiliates

  def initialize managers, payments, user_data, states
    @managers = managers.blank? ? Manager.all : managers
    @payments = payments.blank? ? Payment.all : payments
    @data     = user_data.blank? ? default_data_for_create : user_data
    @states   = states || [:approve]
  end

  def default_data_for_create
    1.upto(10).map do |i|
      [
        {
          name: 2.times.map{ 6.times.map { [*'a'..'z'].sample }.join  }.join(' ').titleize,
          birthday: Time.now,
          skype: "affiliate#{i}",
          phone_number: 380955151220 + i,
          site_url: "http://affiliate#{i}.com",
          about_affiliate: 'Bla-bla-bla-bla-bla',
          accept_the_license: '1',
        },
        payment_attributes,
        email(i),
        RunSeed::PASSWORD
      ].inject(&:merge)
    end
  end

  def payment_attributes
    p = @payments.sample
    a = case p.name
          when 'Skrill'
            "affiliate#{rand(1000)}@gmail.com"
          when 'Webmoney'
            "Z#{12.times.map{ rand(1..9) }.join}"
          end
    {
      payment_system: p.name,
      account_number: a
    }
  end

  def email id
    email = "affiliate#{id}@gmail.com"
    {
      email: email,
      email_confirmation: email
    }
  end

  def create
    ActiveRecord::Base.transaction do
      @affiliates = @data.map { |p| Affiliate.create(p) }.reject { |a| a.id.nil? }
      @affiliates.map! { |a| Affiliate.confirm_by_token(a.confirmation_token) }
      @affiliates.each do |a|
        a.set_manager_and_change_state(@managers.sample, @states.sample)
      end
      ColorText.set_color("Affiliates", @affiliates)
    end
  end

  def self.create managers=nil, payments=nil, data=nil, states=nil
    new(managers, payments, data, states).create
  end
end
