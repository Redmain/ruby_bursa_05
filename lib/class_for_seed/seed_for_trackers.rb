class SeedForTrackers

  def initialize user_data
    @data = user_data.blank? ? default_data_for_create : user_data
  end

  def default_data_for_create
    100.times.map{ { tracker_code: 6.times.map { rand(1..9) }.join } }
  end

  def create
    ActiveRecord::Base.transaction do
      @trackers = @data.map { |p| Tracker.create(p) }.reject { |t| t.id.nil? }
      ColorText.set_color("Trackers", @trackers)
    end
  end

  def self.create data=nil
    new(data).create
  end
end
