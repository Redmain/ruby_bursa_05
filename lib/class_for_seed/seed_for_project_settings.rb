class SeedForProjectSettings

  def initialize user_data
    @settings = ProjectSetting.new
    @data     = user_data.blank? ? default_data_for_create : user_data
  end

  def default_data_for_create
    {
      company_name: 'Quintessence',
      rules: "<p>Не курить на сайте</p>\r\n<p>Не пить на сайте</p>\r\n<p>Не есть на сайте</p>\r\n<p>Не спать на сайте</p>\r\n<p>Не прелюбодействовать на сайте</p>\r\n<p>Не завидовать на сайте</p>\r\n<p>Не убивать на сайте</p>\r\n<p>Не жадничать на сайте</p>\r\n<p>Не грустить на сайте</p>\r\n<p>Не злиться на сайте</p>\r\n<p>Не возвышать себя на сайте</p>\r\n<p>Не высокомерничать на сайте</p>",
      redirect_link: 'http://lotospoker.com/?serial={tracker_id}&aid={zone_id}',
      affiliate_link: 'http://click.lotospoker.com/?serial={tracker_id}&aid={zone_id}',
      max_trackers: 10
    }
  end

  def create
    result = @data.each { |k, v| @settings.send("#{k}=", v) }
    ColorText.set_color("Project settings", result)
  end

  def self.create data=nil
    new(data).create
  end
end
