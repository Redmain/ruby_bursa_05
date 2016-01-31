class SeedForManagers

  def initialize user_data
    @data = user_data.blank? ? default_data_for_create : user_data
  end

  def default_data_for_create
    ['Anri Ounruko', 'Frederiko De El Shtorts', 'Rekardio Enrik'].map.with_index(1) do |v, i|
      {
        name: v,
        email: "manager#{i}@gmail.com"
      }.merge(RunSeed::PASSWORD)
    end
  end

  def create
    ActiveRecord::Base.transaction do
      @managers = @data.map { |p| Manager.create(p) }.reject { |m| m.id.nil? }
      @managers.map! { |a| Manager.confirm_by_token(a.confirmation_token) }
      ColorText.set_color("Managers", @managers)
    end
  end

  def self.create data=nil
    new(data).create
  end
end
