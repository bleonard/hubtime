class Activity
  attr_reader :username, :start_time, :end_time
  
  class Period
    attr_reader :example, :label, :compiled
    def initialize(label, example_time=nil)
      @example = example_time
      @label = label
      @children = {}
      @compiled = {}
    end
    
    def add(commit)
      self.commits << commit
      if self.class.child_class
        klass = self.class.child_class
        key = klass.display(commit.time)
        @children[key] ||= klass.new(key, commit.time)
        @children[key].add(commit)
      end
    end
    
    def compile!(parent)
      first = nil
      last = nil
      @compiled = {}
      child_keys(parent).each do |key|
        @compiled[key] = @children[key]
        if @compiled[key]
          first ||= @compiled[key]
          last = @compiled[key]
        else
          @compiled[key] = self.class.child_class.new(key)
        end
      end
      
      first.first! if first
      last.last! if last
      
      @compiled.values.each do |child|
        child.compile!(self)
      end
    end
    
    def commits
      @commits ||= []
    end
    
    def count
      commits.size
    end
    
    def additions
      commits.sum(&:additions)
    end
    
    def deletions
      commits.sum(&:deletions)
    end
    
    def total
      commits.sum(&:total)
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
      if !parent || parent.first?
        @children.keys.sort.first
      else
        first_child_key
      end
    end
    
    def _last_child_key(parent)
      if !parent || parent.last?
        @children.keys.sort.last
      else
        last_child_key
      end
    end
  end
  
  class Forever < Period
    def self.display(time)
      "Time"
    end
    
    def self.child_class
      Year
    end
    
    def first?
      true
    end
    
    def last?
      true
    end
    
    def each(unit, &block)
      unit = unit.to_s
      if unit == "time"
        yield "Time", self
      else
        self.compiled.each do |year_key, year|
          if unit == "year"
            yield "#{year_key}", year
          else
            year.compiled.each do |month_key, month|
              if unit == "month"
                yield "#{year_key}-#{month_key}", month
              else
                month.compiled.each do |day_key, day|
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
  
  
  def initialize(cli, username, num_months)
    Time.zone = "Pacific Time (US & Canada)"  # TODO: command to allow this being set
    @cli = cli
    @username = username
    @start_time = num_months.months.ago.beginning_of_month
    @end_time = Time.zone.now.end_of_month
    
    @time = Forever.new(Time.now)
  end
  
  def generate
    GithubService.owner.all_commits(username, start_time, end_time) do |commit|
      puts commit.to_s
      @time.add(commit)
    end
    puts "....compiling"
    @time.compile!(nil)
  end
  
  def table(unit = :month)
    table = Terminal::Table.new(:headings => [unit.to_s.titleize, 'Commits', 'Impact'])
    
    @time.each(unit) do |label, period|
      table.add_row [label, period.count, period.total]
    end
    table
  end

end