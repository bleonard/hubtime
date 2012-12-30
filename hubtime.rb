#!/usr/bin/env ruby

require 'rubygems'
require 'active_support'
require 'active_support/all'
require 'commander/import'
require 'terminal-table'

load 'vcr.rb'
load 'hub_config.rb'
load 'commit.rb'
load 'github.rb'
load 'activity.rb'


program :version, '0.0.1'
program :description, 'See activity on Github.'
 
command :graph do |c|
  c.syntax = 'hubtime graph [options]'
  c.summary = ''
  c.description = 'Graph your time'
  c.example 'description', 'command example'
  c.option '--months INTEGER', 'How many months of history'
  c.option '--user USERNAME', 'How many months of history'
  c.action do |args, options|
    options.default :months => 12
    months = options.months.to_i
    months = 12 if months <= 0
    user = options.user
    user ||= HubConfig.user
    raise("Need github user name. hubtime config --user USERNAME --token TOKEN") unless user
    
    activity = Activity.new(self, user, months)
    activity.generate
    
  end
end

command :table do |c|
  c.syntax = 'hubtime table [options]'
  c.summary = ''
  c.description = 'Graph your time'
  c.example 'description', 'command example'
  c.option '--months INTEGER', 'How many months of history'
  c.option '--user USERNAME', 'How many months of history'
  c.action do |args, options|
    options.default :months => 12
    months = options.months.to_i
    months = 12 if months <= 0
    user = options.user
    user ||= HubConfig.user
    raise("Need github user name. hubtime config --user USERNAME --token TOKEN") unless user
    
    activity = Activity.new(self, user, months)
    activity.generate
    puts activity.table
    
  end
end

command :config do |c|
  c.syntax = 'hubtime config --user USERNAME --token TOKEN'
  c.summary = ''
  c.description = 'Sets your details'
  c.example 'description', 'command example'
  c.option '--user USERNAME', 'Github user name'
  c.option '--token TOKEN', 'Github access token'
  c.action do |args, options|
    if options.token || options.user
      raise("Need access token") unless options.token
      raise("Need github user name") unless options.user
      HubConfig.store(options.user, options.token)
      puts "Set config..."
    else
      puts "Current config..."
    end
    
    puts "  Username: #{HubConfig.user}"
    puts "     Token: #{HubConfig.token}"
    
    unless options.token || options.user
      puts "To set, use command: hubtime config --user USERNAME --token TOKEN" 
    end
    
    puts ""
  end
end

command :auth do |c|
  c.syntax = 'hubtime auth'
  c.summary = ''
  c.description = 'Generates a token'
  c.example 'description', 'command example'
  c.action do |args, options|
    username = ask("Github Username: ")
    password = ask("Github Password: ") { |q| q.echo = "*" }
    
    raise "Need a username" if username.blank?
    raise "Need a password" if password.blank?
    
    HubConfig.auth(username, password)
    
    puts "Current config..."
    
    puts "  Username: #{HubConfig.user}"
    puts "     Token: #{HubConfig.token}"
    
    unless options.token || options.user
      puts "To set directly, use command: hubtime config --user USERNAME --token TOKEN" 
    end
    
    puts ""
  end
end

command :repositories do |c|
  c.description = 'Lists known repositories'
  c.action do |args, options|
    GithubService.owner.repositories.each do |name|
      puts name
    end
  end
end
