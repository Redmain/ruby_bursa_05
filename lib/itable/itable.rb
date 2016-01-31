module Itable

  extend ActiveSupport::Concern

  module ClassMethods

    def indexes
      @indexes ||= []
    end

    def index(column_name, options={})
      indexes.push(Itable::Index.new(self.table_name, column_name, options))
    end

    def indexing!
      destroy_unknown_indexes!
      indexes.each(&:indexing)
    end

    def destory_indexes!
      indexes.each(&:destroy)
    end

    def destroy_unknown_indexes!
      names = connection.indexes(self.table_name).select{|i| !indexes.map(&:name).include?(i.name)}
      destroy_all_indexes!(names) unless names.blank?
    end

    def destroy_all_indexes!(names=[])
      names = connection.indexes(self.table_name) if names.blank?
      names.each{ |i| connection.remove_index(self.table_name, name: i.name) }
    end
  end
end
