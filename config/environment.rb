require 'erb'
require "ostruct"
require "yaml"
require "active_record"
require "fileutils"
require 'json'

# All encompassing module for the project
module Sysopia
  def self.env
    @env ||= ENV["SYSOPIA_ENV"] ? ENV["SYSOPIA_ENV"].to_sym : :development
  end

  def self.db_conf
    @db_conf ||= conf.database
  end

  def self.conf
    @conf ||= init_conf
  end

  def self.db_connection
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = Logger::WARN
    ActiveRecord::Base.establish_connection(db_conf[env.to_s])
  end

  def self.read_env
    e_required = open(File.join(__dir__, "env.sh")).map do |l|
      key, val = l.strip.split("=")
      val && key
    end.compact
    e_real = ENV.keys.select { |k| k =~ /^SYSOPIA_/ }
    missing = e_required - e_real
    extra = e_real - e_required
    raise("Missing env variables: #{missing.join(', ')}") unless missing.empty?
    raise("Extra env variables: #{extra.join(', ')}") unless extra.empty?

    return {
      "database" => { env.to_s => { 'host' => ENV["SYSOPIA_DB_HOST"], 'username' => ENV["SYSOPIA_DB_USERNAME"], 'password' => ENV["SYSOPIA_DB_PASSWORD"] } },
      "session_secret" => ENV["SYSOPIA_SESSION_SECRET"],
      "timezone_offset" => ENV["SYSOPIA_TIMEZONE_OFFSET"]
    }
  end

  private

  def self.init_conf
    raw_conf = File.read(File.join(__dir__, "db_config.yml"))
    conf = YAML.load(ERB.new(raw_conf).result)

    #read configurations from system environment variables
    if ENV["SYSOPIA_DB_HOST"]
      conf_new = read_env
      conf_db = conf_new["database"][env.to_s]
      conf_db = conf["database"][env.to_s].merge(conf_new["database"][env.to_s]) do |k, old_v, new_v|
        new_v
      end
      conf["database"][env.to_s] = conf_db
    end

    OpenStruct.new(
      session_secret:   conf["session_secret"],
      database:         conf["database"],
      timezone_offset:  conf["timezone_offset"]
    )
  end
end

Sysopia.db_connection
