class HubConfig
  def self.instance
    @config ||= HubConfig.new
  end
  
  def self.auth(user, password)
    client = Octokit::Client.new(:login => user, :password => password)
    response = client.create_authorization({:client_id => "a5657692d116ce4d155f", :client_secret => "4a4a8b9822b00b26ca586a364af5d5e49243c2a8",
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
  
  def self.threads
    8
  end
  
  def initialize
    @file_name = "config"
    hash = read_file
    @user = hash["user"]
    @token = hash["token"]
  end
  
  def read_file
    YAML.load_file(file)
  end
  
  def write_file(hash)
    File.open(file, 'w' ) do |out|
      YAML.dump(hash, out )
    end
  end
  
  def file
    dir = File.join(File.dirname(__FILE__), "data")
    Dir.mkdir(dir) unless Dir.exists?(dir)
    
    file = File.join(dir, "#{@file_name}.yml")
    
    unless File.exists?(file)
      File.open(file, 'w' ) do |out|
        YAML.dump({}, out )
      end
    end
    file
  end
  
  def store(user, token)
    @user = user
    @token = token
    write_file({"user" => user, "token" => token})
  end
  
  def token
    @token
  end
  
  def user
    @user
  end
  
end
