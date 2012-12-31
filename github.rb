# -*- encoding : utf-8 -*-
Octokit.user_agent = "Hubtime : Octokit Ruby Gem #{Octokit::VERSION}"

class GithubService
  
  def self.owner
    @owner ||= self.new
  end
  
  attr_reader :client
  def initialize
    @client = Octokit::Client.new(:login => HubConfig.user, :password => HubConfig.password, :auto_traversal => true)
    # puts @client.ratelimit_remaining
  end
  
  
  def commits(username, start_time, end_time, &block)
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