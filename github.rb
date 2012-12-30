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
    queue = self.repositories.dup

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

  def repositories
    repos = []
    client.repositories.each do |hash|
      repos << hash.full_name
    end

    user_organizations.each do |org_name|
      client.organization_repositories(org_name).each do |hash|
        repos << hash.full_name
      end
    end
    
    repos.compact.uniq
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
    while repo_name = mutex.synchronize { queue.pop }
      puts "fetching repo: #{repo_name}"
      repo_commits(repo_name, username, start_time, end_time) do |commit|
        mutex.synchronize { block.call commit }
      end
    end
  end
  
  def repo_commits(repo_name, username, start_time, end_time, &block)
    repo_shas(repo_name, username, start_time, end_time) do |sha|
      hash = repo_sha(repo_name, sha)
      next unless hash.is_a?(Hashie::Mash)
      next unless hash.sha
      commit = Commit.new(hash, repo_name, username)
      block.call commit
    end
  end
    
  def user_organizations
    names = []
    client.organizations.each do |hash|
      names << hash.login
    end
    names.compact.uniq
  end
  
  def repo_sha(repo_name, sha)
    VCR.use_cassette("#{repo_name}/shas/#{sha}", :record => :new_episodes) do
      return client.commit(repo_name, sha)
    end
  end
  
  def commits_window(repo_name, username, since_time, until_time)
    options = { :author => username }
    options[:since] = since_time.iso8601
    options[:until] = until_time.iso8601
    
    if Time.now < until_time
      # NO VCR because now is in the window
      return client.commits(repo_name, "master", options)
    else
      # it's over, cache it
      # puts "#{repo_name}/#{username}/commits/#{since_time.to_i}-#{until_time.to_i}"
      VCR.use_cassette("#{repo_name}/#{username}/commits/#{since_time.to_i}-#{until_time.to_i}", :record => :new_episodes) do
         return client.commits(repo_name, "master", options)
      end
    end
  end
    
  
  def repo_shas(repo_name, username, start_time, end_time, &block)
    eq_count = 5  # number of last five shas to be the same, allows caching even if end-time changes but no new commits
    eq_cache_key = nil
    
    cache = Cacher.new("#{repo_name}/#{username}/shas/")
    total_cache_key = "#{start_time.to_i}-#{end_time.to_i}"
    if cached = cache.read(total_cache_key)
      # fully cached
      cached.each { |sha| block.call sha }
      return
    end
    
    shas = []
    fetch_repo_shas(repo_name, username, start_time, end_time) do |sha|
      shas << sha
      block.call sha
      
      if shas.size == eq_count
        eq_cache_key = "#{start_time.to_i}-#{shas[0...eq_count].join("_")}"
        if cached = cache.read(eq_cache_key)
          # given them the rest
          # MAYBE: could also do this halfway through
          #        would call, concat, skip and change the key below
          rest = cached[eq_count..-1]
          rest.each { |sha| block.call sha }
          return
        end
      end
    end
    
    cache.write(eq_cache_key, shas) if eq_cache_key
    cache.write(total_cache_key, shas)
    return
  end
  
  def fetch_repo_shas(repo_name, username, start_time, end_time, &block)
    until_time = end_time
    between = 1.day
    while until_time >= start_time
      since_time = until_time - between
      since_time = start_time if since_time < start_time
      
      commits = commits_window(repo_name, username, since_time, until_time)
      count = 0
      commits.each do |hash|
        next unless hash.is_a?(Hashie::Mash)
        next unless hash.sha
        
        block.call hash.sha
        count += 1
      end
      
      # vary the size of the gaps
      if count == 0
        between = between * 2
        between = 1.month if between > 1.month
      elsif count > 30
        between = between / 2
      elsif between > 1.week
        between = 1.week
      end
      
      until_time = since_time - 1.second
    end
  end
  
end