#!/usr/bin/env ruby

require 'rubygems'
require 'active_support'
require 'active_support/all'
require 'commander/import'
require 'terminal-table'
require 'fileutils'
require 'yaml'
require 'erubis'
require 'hashie'

load 'cacher.rb'
load 'hub_config.rb'
load 'commit.rb'
load 'github.rb'
load 'activity.rb'
load 'repo.rb'


program :version, '0.0.1'
program :description, 'See activity on Github.'
 
command :impact do |c|
  c.syntax = 'hubtime impact'
  c.summary = ''
  c.description = 'Graph your additions and deletions'
  c.example 'description', 'command example'
  c.option '--months INTEGER', 'How many months of history'
  c.option '--user USERNAME', 'Which Github user'
  c.action do |args, options|
    options.default :months => 12
    activity = Activity.new(self, options.user, options.months)
    file = activity.impact
    puts "saved: #{file}"
    `open #{file}`
  end
end

command :graph do |c|
  c.syntax = 'hubtime graph [commits|impact|additions|deletions]'
  c.summary = ''
  c.description = 'Graph a single count'
  c.example 'description', 'command example'
  c.option '--months INTEGER', 'How many months of history'
  c.option '--user USERNAME', 'Which Github user'
  c.action do |args, options|
    options.default :months => 12
    options.default :data => "count"
    type = args.first
    type ||= "commits"
    type = "count" if type == "commits"
    activity = Activity.new(self, options.user, options.months)
    file = activity.graph(type)
    puts "saved: #{file}"
    `open #{file}`
  end
end

command :pie do |c|
  c.syntax = 'hubtime pie [commits|impact|additions|deletions]'
  c.summary = ''
  c.description = 'Graph a pie chart by repository'
  c.example 'description', 'command example'
  c.option '--months INTEGER', 'How many months of history'
  c.option '--user USERNAME', 'Which Github user'
  c.action do |args, options|
    options.default :months => 12
    options.default :data => "count"
    type = args.first
    type ||= "commits"
    type = "count" if type == "commits"
    activity = Activity.new(self, options.user, options.months)
    file = activity.pie(type)
    puts "saved: #{file}"
    `open #{file}`
  end
end

command :table do |c|
  c.syntax = 'hubtime table [options]'
  c.summary = ''
  c.description = 'Table your time'
  c.example 'description', 'command example'
  c.option '--months INTEGER', 'How many months of history'
  c.option '--user USERNAME', 'How many months of history'
  c.option '--unit (year|month|day)', 'Granularity of the results'
  c.action do |args, options|
    options.default :months => 12
    options.default :unit => "month"
    activity = Activity.new(self, options.user, options.months)
    puts activity.table(options.unit)
  end
end

command :spark do |c|
  c.syntax = 'hubtime spark [options]'
  c.summary = ''
  c.description = 'Graph your time'
  c.example 'description', 'command example'
  c.option '--months INTEGER', 'How many months of history'
  c.option '--user USERNAME', 'How many months of history'
  c.option '--unit (year|month|day)', 'Granularity of the results'
  c.option '--data (count|impact|additions|deletions)', 'Type of results'
  c.action do |args, options|
    options.default :months => 12
    options.default :unit => "month"
    options.default :data => "impact"
    activity = Activity.new(self, options.user, options.months)
    puts activity.spark(options.unit, options.data)
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
  c.syntax = 'hubtime repositories'
  c.description = 'Lists known repositories'
  c.option '--user USERNAME', 'Github user name'
  c.action do |args, options|
    user = options.user
    user ||= HubConfig.user
    GithubService.owner.repositories(user).each do |name|
      puts name
    end
  end
end
