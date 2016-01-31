namespace :db do

  desc 'indexing'
  task indexing: :environment do

    models = if ENV['MODELS'].blank?
      ActiveRecord::Base.connection.tables
    else
      ENV['MODELS'].split(',')
    end.map{|x|x.classify.safe_constantize}.compact

    models.each(&:indexing!)

    Rake::Task['pg_partman:reapply_indexes'].invoke('-p public.daily_players_statistics')
    Rake::Task['pg_partman:reapply_indexes'].reenable
    Rake::Task['pg_partman:reapply_indexes'].invoke('-p public.modified_daily_players_statistics')

    Rake::Task["db:schema:dump"].reenable
    Rake::Task["db:schema:dump"].invoke
    Rake::Task["db:structure:dump"].reenable
    Rake::Task["db:structure:dump"].invoke
  end
end
