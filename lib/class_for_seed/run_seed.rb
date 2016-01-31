class RunSeed

  PASSWORD = {
              password: 'Qwerty123',
              password_confirmation: 'Qwerty123'
             }

  def initialize options
    SeedForProjectSettings.create options.delete(:project_settings_data)
    @admins = SeedForAdmins.create options.delete(:admins_data)
    @managers = SeedForManagers.create options.delete(:managers_data)
    @payments = SeedForPayments.create options.delete(:payments_data)
    @conditions = SeedForConditions.create options.delete(:conditions_data)
    @condition_items = SeedForConditionItems.create(@conditions, options.delete(:condition_items_data))
    @condition_steps = SeedForConditionSteps.create(@conditions, options.delete(:condition_steps_data))
    @condition_step_items = SeedForConditionStepItems.create(@condition_steps, options.delete(:condition_step_items_data))
    @trackers = SeedForTrackers.create options.delete(:trackers_data)
    @affiliates = SeedForAffiliates.create(@manages, @payments, options.delete(:affiliate_data))
    # @statistics = SeedForStatistics.create(options.delete(:statistic_data))
  end

  def self.run options={}
    new(options)
    puts ColorText.set_color("Done")
  end
end
