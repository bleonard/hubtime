class Commit
  
  attr_reader :repo_name, :sha, :additions, :deletions, :committer, :time
  def initialize(hash, repo_name = nil, committer = nil)
    @repo_name = repo_name  # or figure it out
    @sha = hash["sha"]
    @additions = hash["stats"]["additions"].to_i
    @deletions = hash["stats"]["deletions"].to_i
    @committer = committer  # or figure it out
    @time = parse_time(hash)
  end
  
  def to_s
    "#{time.strftime('%F')} commit: #{repo_name} : #{sha} by #{committer} with #{additions} additions and #{deletions} deletions}"
  end
  
  def total
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