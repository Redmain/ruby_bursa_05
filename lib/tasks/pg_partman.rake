namespace :pg_partman do
  desc "Undo partition (for help params: '-h')"
  task :undo_partition, [:params] => :environment do |t, args|
    fail ArgumentError unless args[:params]
    params = args[:params]

    sh "/usr/bin/env python\s" \
       "#{Rails.root}/db/pg_partman/bin/undo_partition.py\s" \
       "#{params} -c '#{connection_string}'"
  end

  desc "Migrate data to partitions (for help params: '-h')"
  task :partition_data, [:params] => :environment do |t, args|
    fail ArgumentError unless args[:params]
    params = args[:params]

    sh "/usr/bin/env python\s" \
       "#{Rails.root}/db/pg_partman/bin/partition_data.py\s" \
       "#{params} -c '#{connection_string}'"
  end

  desc "Reapply indexes for partitions (for help params: '-h')"
  task :reapply_indexes, [:params] => :environment do |t, args|
    fail ArgumentError unless args[:params]
    params = args[:params]

    sh "/usr/bin/env python\s" \
       "#{Rails.root}/db/pg_partman/bin/reapply_indexes.py\s" \
       "#{params} -c '#{connection_string}'"
  end

  desc "Reapply foreign keys for partitions (for help params: '-h')"
  task :reapply_foreign_keys, [:params] => :environment do |t, args|
    fail ArgumentError unless args[:params]
    params = args[:params]

    sh "/usr/bin/env python\s" \
       "#{Rails.root}/db/pg_partman/bin/reapply_foreign_keys.py\s" \
       "#{params} -c '#{connection_string}'"
  end

  desc "Dump partition (for help params: '-h')"
  task :dump_partition, [:params] => :environment do |t, args|
    fail ArgumentError unless args[:params]
    params = args[:params]

    sh "/usr/bin/env python\s" \
       "#{Rails.root}/db/pg_partman/bin/dump_partition.py\s" \
       "#{params} -c '#{connection_string}'"
  end

  desc "Check unique constraint for partitions (for help params: '-h')"
  task :check_unique_constraint, [:params] => :environment do |t, args|
    fail ArgumentError unless args[:params]
    params = args[:params]

    sh "/usr/bin/env python\s" \
       "#{Rails.root}/db/pg_partman/bin/check_unique_constraint.py\s" \
       "#{params} -c '#{connection_string}'"
  end

  desc "Reapply constraints for partitions (for help params: '-h')"
  task :reapply_constraints, [:params] => :environment do |t, args|
    fail ArgumentError unless args[:params]
    params = args[:params]

    sh "/usr/bin/env python\s" \
       "#{Rails.root}/db/pg_partman/bin/reapply_constraints.py\s" \
       "#{params} -c '#{connection_string}'"
  end

  def connection_string
    dbconfig =
      ActiveRecord::Base.configurations[ENV['RAILS_ENV'] || 'development']

    "host=#{dbconfig['host']}\s" \
    "dbname=#{dbconfig['database']}\s" \
    "user=#{dbconfig['username']}\s" \
    "password=#{dbconfig['password']}"
  end
end
