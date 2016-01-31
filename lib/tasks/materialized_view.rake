namespace :db do

  desc 'create_materialized_views'
  task create_materialized_views: :environment do

    views = MaterializedView::LIST_OF_VIEWS_ORDER

    views.each{ |v| v.safe_constantize.create_view }

    Rake::Task["db:schema:dump"].invoke
    Rake::Task["db:schema:dump"].reenable
    Rake::Task["db:structure:dump"].invoke
    Rake::Task["db:structure:dump"].reenable
  end
end
