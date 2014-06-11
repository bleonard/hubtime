# -*- encoding : utf-8 -*-
module Hubtime
  class Commit
    attr_reader :repo_name, :sha, :additions, :deletions, :committer, :time
    def initialize(hash, repo_name = nil, committer = nil)
      @repo_name = repo_name  # or figure it out
      @sha = hash["sha"]
      @additions = hash["stats"]["additions"].to_i
      @deletions = hash["stats"]["deletions"].to_i
      @committer = committer
      @committer = username_from_hash(hash) if !@committer || @committer == "all"
      @time = parse_time(hash)
    end

    def username_from_hash(hash)
      out = nil
      out = hash["author"]["login"] if out.blank? && hash["author"]
      out = hash["commit"]["author"]["login"] if out.blank? && hash["commit"] && hash["commit"]["author"]
      out = hash["author"]["email"] if out.blank? && hash["author"]
      out = hash["commit"]["author"]["email"] if out.blank? && hash["commit"] && hash["commit"]["author"]
      
      out = "unknown" if out.blank?
      out
    end

    def to_s
      "#{time.strftime('%F')} commit: #{repo_name} : #{sha} by #{committer} with #{additions} additions and #{deletions} deletions}"
    end

    def count
      return 0 if impact <= 0
      1
    end

    def impact
      additions + deletions
    end


    protected

    def parse_time(hash)
      return nil unless hash["commit"]
      if hash["commit"]["author"]
        return Time.parse(hash["commit"]["author"]["date"]) if hash["commit"]["author"]["date"]
      end
      if hash["commit"]["committer"]
        return Time.parse(hash["commit"]["committer"]["date"]) if hash["commit"]["committer"]["date"]
      end
      return nil
    end
  end
end
