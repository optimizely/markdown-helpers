require 'net/http'
require 'octokit'
require 'yaml'

# Class to help verify local and external links
class LinkChecker
  HTTP_ERRORS = [
    EOFError,
    Errno::ECONNRESET,
    Errno::EINVAL,
    Net::HTTPBadResponse,
    Net::HTTPHeaderSyntaxError,
    Net::ProtocolError,
    Timeout::Error,
    SocketError
  ]
  def initialize(config_file)
    @config = YAML.load_file(config_file)
    unless @config['include'] && @config['include'].any?
      puts "Must declare files in 'include' of config".red
      exit 1
    end
    @broken_links = []
  end

  def check
    @config['include'].each do |included|
      included_object = IncludeItem.new(included)
      included_object.check_paths
      @broken_links << included_object.broken_links.flatten
    end
    @broken_links.flatten!
    if @broken_links.any?
      @broken_links.each do |link_hash|
        output = "Broken link: '#{link_hash['link']}'\n" \
          " in file: '#{link_hash[:file]}'\n" \
          " on line '#{link_hash[:line_number]}'"
        puts output.red
      end
      exit(1)
    else
      puts 'No broken links :)'
    end
  end

  # Helper class for dealing with each included item in config
  class IncludeItem
    attr_reader :broken_links

    def initialize(config)
      @config = config
      @broken_links = []
      @config['replacements'] ||= {}
      @config['private_github'] ||= false
      return unless @config['private_github']
      unless ENV['GITHUB_OAUTH_TOKEN']
        puts "Must specify 'GITHUB_OAUTH_TOKEN' env variable to use 'private_github' config option"
        exit(1)
      end
      @github_client = Octokit::Client.new(access_token: ENV['GITHUB_OAUTH_TOKEN'])
    end

    # iterate over list of paths
    def check_paths
      @config['paths'].each do |path|
        check_path(path)
      end
    end

    # glob each path
    def check_path(path)
      files = Dir.glob(path).select { |f| File.file?(f) } # only want files
      files.each do |filename|
        check_file(filename)
      end
    end

    def check_file(filename)
      file = File.open(filename, 'r')
      file.each_with_index do |line, index|
        return false if @config['exclude_comment'] && line.include?(@config['exclude_comment'])
        links = line.scan(@config['pattern']).flatten
        check_links(links, filename, index + 1) if links.any?
      end
    end

    def check_links(links, file, line_number)
      links.each do |link|
        link = replace_values(link)
        link = link.sub(/#.*$/, '') # scrub the anchor
        next if check_link(link, file)
        @broken_links << {
          'link' => link,
          :file => file,
          :line_number => line_number
        }
      end
    end

    def check_link(link, file)
      if link.match(%r{https://github.com}) && @config['private_github']
        check_github_link(link)
      elsif link.match(/^http.*/)
        check_external_link(link)
      elsif link.match(/^#.*/)
        check_section_link(link, file)
      else
        check_internal_link(link, file)
      end
    end

    def check_github_link(link)
      repo = link.match(%r{github\.com/([^/]*/[^/]*)/.*})[1]
      path = link.match(%r{github\.com/.*/.*/blob/[^/]*/(.*)})[1]
      begin
        @github_client.rate_limit
        @github_client.contents(repo, path: path)
      rescue Octokit::NotFound
        return false
      end
      true
    end

    def check_external_link(link)
      uri = URI(link)
      begin
        response = Net::HTTP.get_response(uri)
      rescue *HTTP_ERRORS
        puts "Error querying #{link}".red
        return false
      end
      response.is_a?(Net::HTTPSuccess) ? true : false
    end

    def check_section_link(link, file)
      section = link.sub(%r{/#*/}, '').split('-').each(&:capitalize).join(' ')
      File.readlines(file).grep(/#{section}/i).size > 0
    end

    def check_internal_link(link, file)
      File.exist?(File.join(File.dirname(file), link)) ? true : false
    end

    def replace_values(link)
      @config['replacements'].each do |pair|
        link = link.sub(pair['match'], pair['value'])
      end
      link
    end
  end
end

# Add colorize to the String class
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end
end
