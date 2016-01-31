class SeedForConditionItems

  def initialize conditions, user_data
    @conditions = conditions.blank? ? Condition.all : conditions
    @data = user_data.blank? ? default_data_for_create : user_data
  end

  def default_data_for_create
    @conditions.inject({}) do |res, e|
      res.merge(
        (ConditionItem::OBTAINED_RESULT[e.type_of_transaction] || []).inject({}) do |res, (key, obtained_result)|
          res.deep_merge(
            e.id => {
              obtained_result => {
                obtained_result: obtained_result,
                condition_for_comparison: ConditionItem::CONDITION_FOR_COMPARISON.keys.sample,
                desired_value: rand(1..70)
              }
            }
          )
        end
      )
    end
  end

  def create
    ActiveRecord::Base.transaction do
      @condition_items =  @conditions.map do |c|
                            c.condition_items.create(@data[c.id].try(:values))
                          end.flatten.reject { |csi| csi.id.nil? }
      ColorText.set_color("ConditionItems", @condition_items)
    end
  end

  def self.create conditions=nil, data=nil
    new(conditions, data).create
  end
end
