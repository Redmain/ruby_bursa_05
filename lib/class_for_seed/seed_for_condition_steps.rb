class SeedForConditionSteps

  def initialize conditions, user_data
    @data = user_data
    @conditions = conditions.blank? ? Condition.all : conditions
  end

  def default_data_for_create
    ['basic'].inject({}) do |res, key|
      res.merge({
        key =>
          1.upto(rand(1..6)).map do |i|
            {
              condition_type: key,
              payment_size: rand(1..99)
            }
          end
      })
    end
  end

  def get_data
    @data.blank? ? default_data_for_create : @data
  end

  def create
    ActiveRecord::Base.transaction do
      @condition_steps =  @conditions.map do |c|
                                      ['basic', c.not_only_basic? ? c.additional_condition : 'basic'].uniq.map do |type|
                                        get_data[type].map do |p|
                                          c.condition_steps.create(p)
                                        end
                                      end
                                    end.flatten.reject { |cs| cs.id.nil? }
      ColorText.set_color("ConditionSteps", @condition_steps)
    end
  end

  def self.create conditions=nil, data=nil
    new(conditions, data).create
  end
end