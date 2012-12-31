# -*- encoding : utf-8 -*-

class HubConfig
  def self.instance
    @config ||= HubConfig.new
  end
  
  def self.auth(user, password)
    client = Octokit::Client.new(:login => user, :password => password)
    response = client.create_authorization({:client_id => self.client_id, :client_secret => self.client_secret,
          :scopes => ["repo", "user"], :note => "Hubtime", :note_url=> "https://github.com/bleonard/hubtime"})
    raise "Error getting Github token" unless response["token"]
    store(user, response["token"])
  end
  
  def self.store(user, token)
    instance.store(user, token)
  end
  
  def self.user
    instance.user
  end
  
  def self.token
    instance.token
  end
  
  def self.ignore
    instance.ignore
  end
  
  def self.add_ignore(repo_name)
    instance.add_ignore(repo_name)
  end
  
  def self.threads
    8
  end
  
  def self.client_id
    "fcb998c47db26c1e0339"
  end
  
  def self.client_secret
    "5687e5f7ae00a76ed309efb01a5583a8cdd4a1c0"
  end
  
  attr_reader :user, :token, :ignore
  def initialize
    @file_name = "config"
    hash = read_file
    @user = hash["user"]
    @token = hash["token"]
    @ignore = hash["ignore"] || []
  end
  
  def read_file
    YAML.load_file(file)
  end
  
  def write_file!
    hash = {}
    ["user", "token", "ignore"].each do |key|
      hash[key] = instance_variable_get("@#{key}")
    end
    
    File.open(file, 'w' ) do |out|
      YAML.dump(hash, out)
    end
  end
  
  def file
    file = File.join(File.dirname(__FILE__), "config.yml")
    
    unless File.exists?(file)
      File.open(file, 'w' ) do |out|
        YAML.dump({}, out )
      end
    end
    file
  end
  
  def add_ignore(repo_name)
    @ignore << repo_name
    @ignore.uniq!
    write_file!
  end
  
  def store(user, token)
    @user = user
    @token = token
    write_file!
  end
  
end
