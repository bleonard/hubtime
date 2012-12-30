require 'octokit'

class GithubService
  def self.owner
    @owner ||= new(HubConfig.user, HubConfig.token)
  end
  
  def all_commits(username, start_time, end_time, &block)
    commits = []
    repositories.each do |repo_name|
      repo_shas(repo_name, username, start_time, end_time) do |sha|
        hash = repo_sha(repo_name, sha)
        next unless hash.sha
        commit = Commit.new(hash, repo_name, username)
        if block_given?
          block.call commit
        else
          commits << commit
        end
      end
    end
    commits
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
  
  attr_accessor :login, :token, :client
  def initialize(login, token)
    self.login = login
    self.token = token
    self.client = Octokit::Client.new(:login => login, :oauth_token => token, :auto_traversal => true)
  end
  
  protected
  
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
      VCR.use_cassette("#{repo_name}/commits/#{username}/#{since_time.to_i}-#{until_time.to_i}", :record => :new_episodes) do
         return client.commits(repo_name, "master", options)
      end
    end
  end
    
  
  def repo_shas(repo_name, username, start_time, end_time, &block)
    shas = []

    until_time = end_time
    between = 1.day
    while until_time >= start_time
      since_time = until_time - between
      since_time = start_time if since_time < start_time
      
      commits = commits_window(repo_name, username, since_time, until_time)
      
      # vary the size of the gaps
      if commits.size == 0
        between = between * 2
        between = 1.month if between > 1.month
      elsif commits.size > 30
        between = between / 2
      elsif between > 1.week
        between = 1.week
      end
      
      commits.each do |hash|
        next unless hash.is_a?(Hashie::Mash)
        next unless hash.sha
        
        if block_given?
          block.call hash.sha
        else
          shas << hash.sha
        end
      end
      until_time = since_time - 1.second
    end
    
    shas.compact.uniq
  end
  
end