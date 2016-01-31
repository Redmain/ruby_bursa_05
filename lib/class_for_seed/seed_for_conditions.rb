class SeedForConditions

  def initialize user_data
    @data = user_data.blank? ? default_data_for_create : user_data
  end

  def default_data_for_create
    1.upto(6).map do |i|
      type_of_transaction = Condition::TYPE_OF_TRANSACTION.values.sample
      {
        title: "Container for conditions \##{i}",
        description: "Container for conditions ##{i}. I\'m serious, it is a container for conditions ##{i}",
        type_of_transaction: type_of_transaction,
        additional_condition: 'none'#Condition::ADDITIONAL_CONDITION[type_of_transaction].values.sample
      }
    end
  end

  def create
    ActiveRecord::Base.transaction do
      @conditions = @data.map { |p| Condition.create(p) }.reject { |c| c.id.nil? }
      ColorText.set_color("Conditions", @conditions)
    end
  end

  def self.create data=nil
    new(data).create
  end
end
