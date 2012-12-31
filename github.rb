# -*- encoding : utf-8 -*-

require 'octokit'
require 'thread'
require 'digest/md5'

class GithubService
  def self.owner
    @owner ||= new(HubConfig.threads, HubConfig.user, HubConfig.token)
  end
  
  def all_commits(username, start_time, end_time, &block)
    mutex = Mutex.new
    queue = self.repositories(username).dup

    if self.thread_count == 1
      mutex_commits(mutex, queue, username, start_time, end_time, block)
    else
      self.thread_count.times.map {
        Thread.new do
          mutex_commits(mutex, queue, username, start_time, end_time, block)
        end
      }.each(&:join)
    end
  end

  def repositories(username)
    repos = []

    client.repositories.each do |hash|
      repos << hash.full_name
    end

    unless username == client.login
      client.repositories(username).each do |hash|
        repos << hash.full_name
      end
    end

    self.organizations(username).each do |org_name|
      client.organization_repositories(org_name).each do |hash|
        repos << hash.full_name
      end
    end
    
    # return these, ignoring requested ones
    repos.compact.uniq - HubConfig.ignore
  end
  
  attr_accessor :client, :thread_count
  def initialize(thread_count, login, token)
    self.thread_count = thread_count
    Octokit.client_id = HubConfig.client_id
    Octokit.client_secret = HubConfig.client_secret
    self.client = Octokit::Client.new(:login => login, :oauth_token => token, :auto_traversal => true)
    # puts self.client.ratelimit_remaining
  end
  
  protected
  
  def mutex_commits(mutex, queue, username, start_time, end_time, block)
    while repo_name = mutex.synchronize { queue.shift }
      puts "fetching repo: #{repo_name}"
      repo = Repo.new(client, repo_name, username, start_time, end_time)
      repo.commits do |commit|
        mutex.synchronize { block.call commit }
      end
    end
  end
 
  def organizations(username)
    names = []
    
    client.organizations.each do |hash|
      names << hash.login
    end
   
    unless username == client.login
      client.organizations(username).each do |hash|
        names << hash.login
      end
    end
    
    names.compact.uniq
  end

end