# -*- encoding : utf-8 -*-

require 'openssl'
require 'digest/sha2'

module Hubtime
  class HubConfig
    def self.instance
      @config ||= HubConfig.new
    end

    def self.auth(user, password)
      store(user, password)
    end

    def self.store(user, password)
      instance.store(user, password)
    end

    def self.user
      instance.user
    end

    def self.password
      instance.password
    end

    def self.display_password
      '*' * password.size
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

    attr_reader :user, :password, :ignore
    def initialize
      @file_name = "config"
      hash = read_file
      @user = hash["user"]
      @password = Stuff.decrypt(hash["password"])
      @ignore = hash["ignore"] || []
    end

    def read_file
      YAML.load_file(file)
    end

    def write_file!
      hash = {}
      ["user", "password", "ignore"].each do |key|
        hash[key] = instance_variable_get("@#{key}")
      end

      hash["password"] = Stuff.encrypt(hash["password"])

      File.open(file, 'w' ) do |out|
        YAML.dump(hash, out)
      end
    end

    def file
      file = File.join(File.expand_path("."), "hubtime_config.yml")

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

    def store(user, password)
      @user = user
      @password = password
      write_file!
    end

    class Stuff
      def self.key
        sha256 = Digest::SHA2.new(256)
        sha256.digest("better than plain text")
      end
      def self.iv
        "kjfdhkkkjkjhfdskljghfkdjhags"
      end
      def self.encrypt(payload)
        return nil if payload == nil
        aes = OpenSSL::Cipher.new("AES-256-CFB")
        aes.encrypt
        aes.key = key
        aes.iv = iv

        aes.update(payload) + aes.final
      end

      def self.decrypt(encrypted)
        return nil if encrypted == nil

        aes = OpenSSL::Cipher.new("AES-256-CFB")
        aes.decrypt
        aes.key = key
        aes.iv = iv
        aes.update(encrypted) + aes.final
      end
    end
  end
end
