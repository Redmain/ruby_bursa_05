class SeedForAdmins

  def initialize user_data
    @data = user_data.blank? ? default_data_for_create : user_data
  end

  def default_data_for_create
    ['Paul Rodgers', 'Captain Titus'].map.with_index(1) do |v, i|
      {
        name: v,
        email: "admin#{i}@gmail.com"
      }.merge(RunSeed::PASSWORD)
    end
  end

  def create
    ActiveRecord::Base.transaction do
      @admins = @data.map { |p| Admin.create(p) }.reject { |a| a.id.nil? }
      @admins.map! { |a| Admin.confirm_by_token(a.confirmation_token) }
      ColorText.set_color("Admins", @admins)
    end
  end

  def self.create data=nil
    new(data).create
  end
end
