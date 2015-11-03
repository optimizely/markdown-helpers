require 'erb'
require 'yaml'

# Class for building an index tree from
# erb and directory root
class DocBuilder
  def initialize(config_file)
    @config = YAML.load_file(config_file)
    @config['base_header'] ||= ''
    @config['base_level'] ||= 1
    if @config['base_level'] < 1
      puts ':base_level must be greater than 0'
      exit
    end
    @config['ignore'] ||= []
    @doc_index = ''
  end

  # recursive call on directories starting at @doc_directory
  # writes indented list block for each directory
  def generate_index(
    options = {
      directory: @config['doc_directory'],
      level: @config['base_level'],
      header_level: @config['base_header']
    }
  )
    sub_directories = Dir.entries(options[:directory])
    directory_last = true
    sub_directories.each do |filename|
      next if ignore_file?(filename, options[:directory])
      path = File.join(options[:directory], filename)
      if File.directory?(path)
        # case where two directories are back to back
        options[:level] = options[:level] - 1 if directory_last && options[:level] > 0
        concat_directory(path, options[:level] + 1, options[:header_level])
        directory_last = true
      else
        concat_file(path, options[:level])
        directory_last = false
      end
    end
  end

  def write
    template = File.read(@config['erb_path'])
    erb = ERB.new(template)
    File.write(@config['output_file'], erb.result(binding))
  end

  private

  # format and concat directory
  def concat_directory(path, level, header_level)
    indent = '  ' * (level)
    description = File.basename(path)
                  .split('_') # split on underscores
                  .map(&:capitalize) # capitalize each word
                  .join(' ') # make it one string
    repo_path = path.sub(File.dirname(@config['output_file']), '.')
    # return if nothing below directory
    return if empty_directory?(path)
    @doc_index << "\n#{indent}#{header_level} [#{description}](#{repo_path})\n"
    generate_index(directory: path, level: level, header_level: header_level + '#')
  end

  # format and concat file
  def concat_file(path, level)
    indent = '  ' * (level)
    line = File.open(path, &:readline)
    repo_path = path.sub(File.dirname(@config['output_file']), '.')
    puts line
    puts path
    description = line.sub(%r{/^#* */}, '').chomp
    @doc_index << "#{indent}- [#{description}](#{repo_path})\n"
  end

  # empty == no subdirectories with .md files
  def empty_directory?(directory)
    Dir.entries(directory).each do |filename|
      next if ignore_file?(filename, directory)
      return false if filename.include?('.md')
      path = File.join(directory, filename)
      return false if File.directory?(path) && !empty_directory?(path)
    end
    return true
  end

  def ignore_file?(filename, directory)
    path = File.join(directory, filename)
    # current or parent dir
    if filename == '.' || filename == '..'
      return true
    # explicit ignore in config
    elsif @config['ignore'].include?(filename)
      return true
    # symlinks, because of infinite loops on dir's
    elsif File.symlink?(path)
      return true
    # is it a non-md file?
    elsif File.file?(path) && ! filename.include?('.md')
      return true
    end
    return false
  end
end
