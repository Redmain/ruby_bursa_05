namespace :db do
  desc "Reset all data in database and execute all migrations"
  task :reset_data do
    Rake::Task["db:migrate:reset"].invoke
    Rake::Task["db:seed"].invoke
  end
end
