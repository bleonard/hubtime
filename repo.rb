# -*- encoding : utf-8 -*-

class Repo
  attr_reader :client, :cacher
  attr_reader :repo_name, :username, :start_time, :end_time
  def initialize(client, repo_name, username, start_time, end_time)
    @client = client
    @repo_name = repo_name
    @username = username
    @start_time = start_time
    @end_time = end_time
    @cacher = Cacher.new("#{repo_name}")
  end
  
  def commits(&block)
    list = self.sha_list
    
    list.each do |sha|
      hash = fetch_sha(sha)
      next unless hash.is_a?(Hashie::Mash)
      next unless hash.sha
      commit = Commit.new(hash, repo_name, username)
      block.call commit
    end
  end
  
  protected
  
  def sha_list
    cache_key = "#{username}/#{start_time.to_i}-#{end_time.to_i}"
    if cached = cacher.read(cache_key)
      return cached
    end
    
    windows = []
    windows << [start_time, end_time]
    result = []
    
    windows.each do |window|
      since_time, until_time = window
      list = commits_window(since_time, until_time)
      result.concat list
    end
    
    cacher.write(cache_key, result)
  end
  
  def commits_window(since_time, until_time)
    cache_key = "#{username}/#{since_time.to_i}-#{until_time.to_i}"
    if cached = cacher.read(cache_key)
      return cached
    end
    
    options = { :author => username }
    options[:since] = since_time.iso8601
    options[:until] = until_time.iso8601
    
    result = []
    commits = client.commits(repo_name, "master", options)
    commits.each do |hash|
      next unless hash.is_a?(Hashie::Mash)
      next unless hash.sha
      result << hash.sha
    end
    
    cacher.write(cache_key, result)
  end
  
  def fetch_sha(sha)
    cache_key = "shas/#{sha}"
    hashie = cacher.read(cache_key)
    return hashie if hashie
    hashie = client.commit(repo_name, sha)
    cacher.write(cache_key, hashie)
  end
  
  
end