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
    self.shas do |sha|
      hash = fetch_sha(sha)
      next unless hash.is_a?(Hashie::Mash)
      next unless hash.sha
      commit = Commit.new(hash, repo_name, username)
      block.call commit
    end
  end
  
  protected
  
  def shas(&block)
    eq_count = 5  # number of last five shas to be the same, allows caching even if end-time changes but no new commits
    eq_cache_key = nil
    
    total_cache_key = "#{username}/shas/times/#{start_time.to_i}-#{end_time.to_i}"
    if cached = cacher.read(total_cache_key)
      # fully cached
      cached.each { |sha| block.call sha }
      return
    end
    
    shas = []
    sha_list do |sha|
      shas << sha
      block.call sha
      
      if shas.size == eq_count
        eq_cache_key = "#{username}/shas/stamps/#{start_time.to_i}-#{shas[0...eq_count].join("_")}"
        if cached = cacher.read(eq_cache_key)
          # given them the rest
          # MAYBE: could also do this halfway through
          #        would call, concat, skip and change the key below
          rest = cached[eq_count..-1]
          rest.each { |sha| block.call sha }
          return
        end
      end
    end
    
    cacher.write(eq_cache_key, shas) if eq_cache_key
    cacher.write(total_cache_key, shas)
    return
  end
  
  def sha_list(&block)
    until_time = end_time
    between = 1.day
    while until_time >= start_time
      since_time = until_time - between
      since_time = start_time if since_time < start_time
      
      commits = commits_window(since_time, until_time)
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
  
  def commits_window(since_time, until_time)
    options = { :author => username }
    options[:since] = since_time.iso8601
    options[:until] = until_time.iso8601
    
    if Time.now < until_time
      # No caching because now is in the window
      return client.commits(repo_name, "master", options)
    else
      # it's over, cache it
      cache_key = "#{username}/commits/#{since_time.to_i}-#{until_time.to_i}"
      hashie = cacher.read(cache_key)
      return hashie if hashie
      hashie = client.commits(repo_name, "master", options)
      cacher.write(cache_key, hashie)
    end
  end
  
  def fetch_sha(sha)
    cache_key = "shas/#{sha}"
    hashie = cacher.read(cache_key)
    return hashie if hashie
    hashie = client.commit(repo_name, sha)
    cacher.write(cache_key, hashie)
  end
  
  
end