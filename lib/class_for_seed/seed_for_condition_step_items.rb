class SeedForConditionStepItems

  def initialize condition_steps, user_data
    @condition_steps = condition_steps.blank? ? ConditionStep.all : condition_steps
    @data = user_data.blank? ? default_data_for_create : user_data
  end

  def default_data_for_create
    @condition_steps.inject({}) do |res, e|
      res.merge(
        (ConditionStepItem::OBTAINED_RESULT[e.condition.type_of_transaction] || []).inject({}) do |res, (key, obtained_result)|
          res.deep_merge(
            e.id => {
              obtained_result => {
                obtained_result: obtained_result,
                condition_for_comparison: ConditionStepItem::CONDITION_FOR_COMPARISON.keys.sample,
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
      @condition_step_items = @condition_steps.map do |cs|
                                cs.condition_step_items.create(@data[cs.id].try(:values))
                              end.flatten.reject { |csi| csi.id.nil? }
      ColorText.set_color("ConditionStepItems", @condition_step_items)
    end
  end

  def self.create condition_steps=nil, data=nil
    new(condition_steps, data).create
  end
end
