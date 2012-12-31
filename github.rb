# -*- encoding : utf-8 -*-

class GithubService
  def self.owner
    Octokit.client_id = HubConfig.client_id
    Octokit.client_secret = HubConfig.client_secret
    @owner ||= new(HubConfig.user, HubConfig.token)
  end
  
  def all_commits(username, start_time, end_time, &block)
    self.repositories(username).each do |repo_name|
      puts "#{repo_name}"
      repo = Repo.new(repo_name, username, start_time, end_time)
      repo.commits do |commit|
        block.call commit
      end
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
  
  attr_accessor :client
  def initialize(login, token)
    self.client = Octokit::Client.new(:login => login, :oauth_token => token, :auto_traversal => true)
    # puts self.client.ratelimit_remaining
  end
  
  protected
  
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