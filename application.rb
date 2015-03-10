#!/usr/bin/env ruby

require "zen-grids"
require "rack/timeout"
require "sinatra"
require "sinatra/base"
require "sinatra/flash"
require "sinatra/redirect_with_flash"
require "haml"
require "sass"
require "childprocess"

#load the gems in gemfile
require 'bundler'
Bundler.require(:default, ENV['SYSOPIA_ENV'])

# load environment
require_relative "config/environment"

# load main files of the app
require_relative "lib/sysopia"
require_relative "routes"
require_relative "helpers"
require_all "models"

configure do
  register Sinatra::Flash
  helpers Sinatra::RedirectWithFlash

  use Rack::MethodOverride
  use Rack::Session::Cookie, secret: Sysopia.conf.session_secret
  use Rack::Timeout
  Rack::Timeout.timeout = 9_000_000

  Compass.add_project_configuration(File.join(File.dirname(__FILE__), "config", "compass.config"))
  #set :server, "webrick"
  set :scss, Compass.sass_engine_options
end


