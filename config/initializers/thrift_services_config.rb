require "yaml"
require "deep_merge"
require "recursive-open-struct"
require 'active_support/core_ext/hash/indifferent_access'

class ThriftConfig
  def self.load
    @services ||= full_config.deep_merge!(env_config)
  end

  private
  def self.full_config
    if user_thrift_services_config.nil?
      thrift_services_config
    else
      thrift_services_config.deep_merge!(user_thrift_services_config)
    end
  end

  def self.env_config
    full_config[ENV.fetch("ENV", "development")]
  end

  def self.thrift_services_config
    load_yaml(thrift_services_config_path)
  end

  def self.user_thrift_services_config
    if File.exists?(user_thrift_services_config_path)
      load_yaml(user_thrift_services_config_path)
    end
  end

  def self.thrift_services_config_path
    full_path "config/thrift_services.yml"
  end

  def self.user_thrift_services_config_path
    full_path "config/thrift_services.user.yml"
  end

  def self.full_path(relative_path)
    File.join("./", relative_path)
  end

  def self.load_yaml(full_path)
    YAML.load(File.read(full_path)).with_indifferent_access
  end
end

THRIFT_SERVICES_CONFIG = ThriftConfig.load
