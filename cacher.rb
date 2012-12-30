# -*- encoding : utf-8 -*-

class Cacher
  def initialize(directory)
    root = File.join(File.dirname(__FILE__), "data", "cache")
    @directory = File.join(root, directory)
    FileUtils.mkdir_p(@directory)
  end
  
  def read(key)
    file_name = File.join(@directory, sanitized_file_name_from(key))
    return nil unless File.exist?(file_name)
    YAML.load(File.read(file_name))
  end
  
  def write(key, value)
    file_name = File.join(@directory, sanitized_file_name_from(key))
    directory = File.dirname(file_name)
    FileUtils.mkdir_p(directory) unless File.exist?(directory)
    File.open(file_name, 'w') {|f| f.write(YAML.dump(value)) }
    value
  end
  
  private
  
  def sanitized_file_name_from(file_name)
    parts = file_name.to_s.split('.')
    file_extension = '.' + parts.pop if parts.size > 1
    base = parts.join('.').gsub(/[^\w\-\/]+/, '_') + file_extension.to_s
    "#{base}.yml"
  end
end