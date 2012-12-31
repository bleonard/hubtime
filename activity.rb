# -*- encoding : utf-8 -*-

class Activity
  
  class Period
    attr_reader :example, :label, :compiled, :children
    attr_reader :total_stats, :repo_stats
    def initialize(label, example_time=nil)
      @example = example_time
      @label = label
      @children = {}
      @total_stats = default_stats
      @repo_stats  = Hash.new{ |hash, key| hash[key] = default_stats }
      @compiled = nil
    end
    
    def add(commit)
      self.commits << commit
      self.total_stats.keys.each do |key|
        self.total_stats[key] += commit.send(key)
      end
      self.repo_stats[commit.repo_name].keys.each do |key|
        self.repo_stats[commit.repo_name][key] += commit.send(key)
      end
      
      if self.class.child_class
        klass = self.class.child_class
        key = klass.display(commit.time)
        @children[key] ||= klass.new(key, commit.time)
        @children[key].add(commit)
      end
    end
    
    def compiled?
      !!@compiled
    end
    
    def compile!(parent)
      return if compiled?
      first = nil
      last = nil
      filled = {}
      child_keys(parent).each do |key|
        filled[key] = @children[key]
        if filled[key]
          first ||= filled[key]
          last = filled[key]
        else
          filled[key] = self.class.child_class.new(key)
        end
      end
      
      first.first! if first
      last.last! if last
      
      filled.values.each do |child|
        child.compile!(self)
      end
      
      @children = filled
      
      @compiled = {}
      @compiled["total_stats"] = self.total_stats
      @compiled["repo_stats"]  = self.repo_stats
          
      @compiled["children"] = {}
      @children.each do |key, period|
        @compiled["children"][key] = period.compiled
      end
    end
    
    def import(stats)
      child_list  = stats.delete("children")
      @compiled    = stats
      @total_stats = stats["total_stats"]
      @repo_stats  = stats["repo_stats"]
      @children = {}
      child_list.each do |key, child_stats|
        @children[key] = self.class.child_class.new(key)
        @children[key].import(child_stats)
      end
    end
    
    def commits
      @commits ||= []
    end
    
    def count
      total_stats["count"]
    end
    
    def additions
      total_stats["additions"]
    end
    
    def deletions
      total_stats["deletions"]
    end
    
    def impact
      total_stats["impact"]
    end
    
    def first!
      @first = true
    end
    
    def first?
      !!@first
    end
    
    def last!
      @last = true
    end
    
    def last?
      !!@last
    end
        
    def child_keys(parent)
      return [] if self.class.child_class.nil?
      
      first = self._first_child_key(parent)
      last = self._last_child_key(parent)
      (first..last).to_a
    end
    
    def _first_child_key(parent)
      if first? && (!parent || parent.first?) && children.keys.size > 0
        children.keys.sort.first
      else
        first_child_key
      end
    end
    
    def _last_child_key(parent)
      if last? && (!parent || parent.last?) && children.keys.size > 0
        children.keys.sort.last
      else
        last_child_key
      end
    end
    
    def default_stats
      {"additions" => 0, "deletions" => 0, "impact" => 0, "count" => 0}
    end
  end
  
  class Forever < Period
    def self.display(time)
      "All"
    end
    
    def self.child_class
      Year
    end
    
    attr_reader :cache_key
    def initialize(cache_key)
      @cache_key = cache_key
      super(self.class.display(Time.zone.now), Time.zone.now)
    end
    
    def self.cacher
      @cacher ||= Cacher.new("activity")
    end
    
    def self.load(username, start_time, end_time)
      key = "#{username}/#{start_time.to_i}-#{end_time.to_i}"
      out = self.new(key)
      if stats = cacher.read(key)
        out.import(stats)
      end
      out
    end
    
    def store!
      raise "not compiled" unless compiled?
      self.class.cacher.write(cache_key, @compiled)
    end
    
    def first?
      true
    end
    
    def last?
      true
    end
    
    def each(unit, &block)
      unit = unit.to_s
      if unit == "all"
        yield "All", self
      else
        self.children.each do |year_key, year|
          if unit == "year"
            yield "#{year_key}", year
          else
            year.children.each do |month_key, month|
              if unit == "month"
                yield "#{year_key}-#{month_key}", month
              else
                month.children.each do |day_key, day|
                  yield "#{year_key}-#{month_key}-#{day_key}", day
                end
              end
            end
          end
        end
      end
    end
  end
  
  class Year < Period
    def self.display(time)
      time.strftime("%Y")
    end
    
    def self.child_class
      Month
    end
    
    def first_child_key
      "01"
    end
    
    def last_child_key
      "12"
    end
  end
  
  class Month < Period
    def self.display(time)
      time.strftime("%m")
    end
    
    def self.child_class
      Day
    end
    
    def first_child_key
      "01"
    end
    
    def last_child_key
      if self.example
        # how many days in this month
        self.class.child_class.display(self.example.end_of_month)
      else
        # TODO: nothing this month?
        "30"
      end
    end
  end
  
  class Day < Period
    def self.display(time)
      time.strftime("%d")
    end
    
    def self.child_class
      nil
    end
  end
  
  attr_reader :username, :start_time, :end_time
  def initialize(cli, username, num_months)
    num_months = num_months.to_i
    num_months = 12 if num_months <= 0
    username ||= HubConfig.user
    raise("Need github user name. hubtime config --user USERNAME --token TOKEN") unless username
    
    Time.zone = "Pacific Time (US & Canada)"  # TODO: command to allow this being set
    @cli = cli
    @username = username
    @start_time = num_months.months.ago.beginning_of_month
    @end_time = Time.zone.now.end_of_month
    
    @time = Forever.load(username, start_time, end_time)
  end
  
  def compile!
    unless @time.compiled?
      GithubService.owner.all_commits(username, start_time, end_time) do |commit|
        @time.add(commit)
      end
      puts "... compiling data for #{username}"
      @time.compile!(nil)
      @time.store!
    end
  end
  
  def table(unit = :month)
    compile!
    table = Terminal::Table.new(:headings => [unit.to_s.titleize, 'Commits', 'Impact', 'Additions', 'Deletions'])
    
    @time.each(unit) do |label, period|
      table.add_row [label, period.count, period.impact, period.additions, period.deletions]
    end
    table
  end
  
  def spark(unit = :month, type = :impact)
    compile!
    data = []
    @time.each(unit) do |label, period|
      data << period.send(type)
    end
    
    ticks=%w[ ▁  ▂  ▃ ▄  ▅  ▆  ▇ ]

    return "" if data.size == 0
    return ticks.last if data.size == 1
    
    range = data.max - data.min
    scale = ticks.length - 1
    distance = data.max.to_f / ticks.size

    str = ''
    data.each do |val|
      if val == 0
        str << " "
      else
        tick = (val / distance).round - 1
        str << ticks[tick]
      end
    end
    str
  end
  
  def impact
    compile!
    
    additions = []
    deletions = []
    impacts   = [] 
    labels    = []
    
    week_additions = 0
    week_deletions = 0
    week_label = nil
    
    total_impact = 0
    
    day = 0
    @time.each(:day) do |label, period|
      day += 1
      week_label ||= label
      week_additions += period.additions
      week_deletions += period.deletions
      total_impact   += period.impact
      
      if (day % 7) == 0
        additions << week_additions
        deletions << week_deletions
        impacts   << total_impact
        
        if (day % 28) == 0
          labels << week_label
        else
          labels << ""
        end
        
        week_additions = 0
        week_deletions = 0
        week_label = nil
      end
    end
    
    charts = File.join(File.dirname(__FILE__), "charts")
    template = File.read(File.join(charts, "impact.erb"))
    template = Erubis::Eruby.new(template)
    html = template.result(:additions => additions, :deletions => deletions, :impacts => impacts, :labels => labels, :username => username)
    
    root = File.join(File.dirname(__FILE__), "data", "charts")
    path = "#{username}-impact-#{start_time.to_i}-#{end_time.to_i}.html"
    file_name = File.join(root, path)
    directory = File.dirname(file_name)
    FileUtils.mkdir_p(directory) unless File.exist?(directory)
    File.open(file_name, 'w') {|f| f.write(html) }
    file_name
  end
  
  def graph(type = :impact)
    compile!
    
    type = type.to_s
    other = "count"
    other = "impact" if type == "count"
    
    data   = []
    others = []
    labels = []
    
    week_data = 0
    week_other = 0
    week_label = nil
    day = 0
    @time.each(:day) do |label, period|
      day += 1
      week_label ||= label
      week_data  += period.send(type)
      week_other += period.send(other)
      
      if (day % 7) == 0
        data   << week_data
        others << week_other
        
        if (day % 28) == 0
          labels << week_label
        else
          labels << ""
        end
        
        week_data = 0
        week_label = nil
        week_other = 0
      end
    end
    
    charts = File.join(File.dirname(__FILE__), "charts")
    template = File.read(File.join(charts, "graph.erb"))
    template = Erubis::Eruby.new(template)
    html = template.result(:data => data, :other => others, :labels => labels, :data_type => type, :other_type => other, :username => username)
    
    root = File.join(File.dirname(__FILE__), "data", "charts")
    path = "#{username}-graph-#{type}-#{start_time.to_i}-#{end_time.to_i}.html"
    file_name = File.join(root, path)
    directory = File.dirname(file_name)
    FileUtils.mkdir_p(directory) unless File.exist?(directory)
    File.open(file_name, 'w') {|f| f.write(html) }
    file_name
  end

end