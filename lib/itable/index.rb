module Itable
  class Index

    attr_reader :name, :options, :columns

    def initialize(table_name, column_name, options = {})
      @table   = table_name
      @columns = column_name
      @name    = options.key?(:name) ? _index_name(name: options.delete(:name)) : _index_name(column: @columns)
      @inc     = options.key?(:include) ? options.delete(:include) : true
      @options = options.merge(name: @name, length: @name.length)
    end

    def indexing
      @inc ? create : destroy
    end

    def create
      connection.add_index(@table, @columns, @options) unless exists?
    end

    def destroy
      connection.remove_index(@table, name: @name) if exists?
    end

    private
      def _index_name(options)
        if options.is_a?(Hash)
          if options[:column]
            table_name = @table.split('_')
            table_name = table_name.count == 1 ? table_name.first : table_name.map(&:first).join
            row_name   = Array(options[:column]).map{ |r| r = r.to_s.split('_'); r.count == 1 ? r.first : r.map(&:first).join }.join('_')
            "index_#{table_name}_#{row_name}"
          elsif options[:name]
            "index_#{table_name}_#{options[:name]}"
          else
            raise ArgumentError, "You must specify the index name"
          end
        else
          _index_name(column: options)
        end
      end

      def exists?
        connection.index_name_exists?(@table, name, true)
      end

      def connection
        ActiveRecord::Base.connection
      end
  end
end
