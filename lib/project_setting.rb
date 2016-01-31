require 'ostruct'

class ProjectSetting < OpenStruct

  extend ActiveModel::Callbacks

  define_model_callbacks :update_file, only: :after
  after_update_file :reset_cache

  def initialize(data=nil)
    @table      = {}
    @file_path  = 'config/application.yml'
    @data       = data || Rails.cache.fetch('application_yml_config'){ YAML.load_file(@file_path) rescue {} }
    @data.each_pair do |k,v|
      @table[k.to_sym] = (v.is_a?(Hash) ? self.class.new(v) : v)
      new_ostruct_member(k)
    end
  end

  def attributes
    each_pair.inject({}) do |res, (k, v)|
      res.deep_merge(k.to_s => (v.is_a?(ProjectSetting) ? v.attributes : v))
    end
  end

  def save
    update_file
  end

  private
    def update_file
      run_callbacks :update_file do
        File.open(@file_path, 'w'){ |f| f.write(YAML.dump(attributes)) }
      end
    end

    def reset_cache
      Rails.cache.delete('application_yml_config')
    end
end
