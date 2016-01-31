Rake::Task["db:migrate"].enhance do

  Rake::Task["db:indexing"].reenable
  Rake::Task["db:indexing"].invoke

  system('annotate -ks') if Rails.env.development?
end
