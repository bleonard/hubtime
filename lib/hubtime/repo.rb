# -*- encoding : utf-8 -*-

require 'thread'

module Hubtime
  class Repo
    attr_reader :cacher, :mutex, :thread_count
    attr_reader :repo_name, :username, :start_time, :end_time
    def initialize(repo_name, username, start_time, end_time)
      @repo_name = repo_name
      @username = username
      @cacher = Cacher.new("#{repo_name}")
      @mutex = Mutex.new
      @thread_count = HubConfig.threads
      
      if end_time < start_time
        @start_time = end_time
        @end_time = start_time
      else
        @start_time = start_time
        @end_time = end_time
      end
    end

    def auto_client
      @auto_client ||= Octokit::Client.new(:login => HubConfig.user, :password => HubConfig.password, :auto_traversal => true)
    end

    def single_client
      @single_client ||= Octokit::Client.new(:login => HubConfig.user, :password => HubConfig.password)
    end

    def commits(&block)
      queue = self.sha_list.dup

      if self.thread_count == 1
        work_sha_queue(queue, block)
      else
        self.thread_count.times.map {
          Thread.new do
            work_sha_queue(queue, block)
          end
        }.each(&:join)
      end

    end

    protected

    def generate_sha_windows

      diff = end_time.to_i - start_time.to_i
      thread_time = diff / self.thread_count

      # seeing this issue https://gist.github.com/4256275
      # when fixed, we can bump these up and remove single_window_check
      max_window_time = 3.days
      min_window_time = 1.day

      between = thread_time
      between = max_window_time if between > max_window_time
      between = min_window_time if between < min_window_time

      windows = []
      until_time = end_time
      while until_time >= start_time
        since_time = until_time - between
        since_time = start_time if since_time < start_time

        windows << [since_time, until_time]

        until_time = since_time - 1.second
      end

      windows
    end

    def single_window_check
      # pagination doesn't work, see if there are even 100 over the whole window
      options = { :author => username }
      options[:since] = start_time.iso8601
      options[:until] = end_time.iso8601
      options[:per_page] = 100
      options[:page] = 1

      commits = single_client.commits(repo_name, "master", options)
      return if commits.size >= 100 # go slower

      result = []
      commits.each do |hash|
        next unless hash.is_a?(Hashie::Mash)
        next unless hash.sha
        result << hash.sha
      end

      result
    end

    def sha_list
      cache_key = "#{username}/#{start_time.to_i}-#{end_time.to_i}"
      # puts "sha_list: #{cache_key}\n"
      if cached = cacher.read(cache_key)
        return cached
      end

      result = single_window_check

      if result.nil?
        queue = self.generate_sha_windows
        result = []

        if self.thread_count == 1
          work_window_queue(queue, result)
        else
          self.thread_count.times.map {
            Thread.new do
              work_window_queue(queue, result)
            end
          }.each(&:join)
        end
      end

      cacher.write(cache_key, result)
    end

    def work_window_queue(queue, result)
      while window = mutex.synchronize { queue.shift }
        since_time, until_time = window
        list = commits_window(since_time, until_time)
        mutex.synchronize { result.concat list }
      end
    end

    def commits_window(since_time, until_time)
      cache_key = "#{username}/#{since_time.to_i}-#{until_time.to_i}"
      #puts "commits_window: #{cache_key}\n"
      if cached = cacher.read(cache_key)
        return cached
      end

      options = { :author => username }
      options[:since] = since_time.iso8601
      options[:until] = until_time.iso8601

      result = []
      commits = auto_client.commits(repo_name, "master", options)
      commits.each do |hash|
        next unless hash.is_a?(Hashie::Mash)
        next unless hash.sha
        result << hash.sha
      end

      cacher.write(cache_key, result.uniq)
    end

    def work_sha_queue(queue, block)
      while sha = mutex.synchronize { queue.shift }
        hash = fetch_sha(sha)
        next unless hash.is_a?(Hashie::Mash)
        next unless hash.sha
        commit = Commit.new(hash, repo_name, username)
        mutex.synchronize { block.call commit }
      end
    end

    def fetch_sha(sha)
      cache_key = "shas/#{sha}"
      hashie = cacher.read(cache_key)
      return hashie if hashie
      hashie = single_client.commit(repo_name, sha)
      cacher.write(cache_key, hashie)
    end
  end
end
