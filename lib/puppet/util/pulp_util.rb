require 'net/http'
require 'net/https'
require 'openssl'
require 'uri'
require 'json'

module Puppet
  module Util
    class PulpcoreUtil
      def initialize (global_config_path = '/etc/pulp/cli.toml', root_config_path = '/root/.config/pulp/cli.toml')
        global_config        = parse_config(global_config_path)
        root_config          = parse_config(root_config_path)
        @config = {}
        @root_config = {}
        @config[:base_url]   = global_config['cli']['base_url']   || "https://localhost"
        @config[:port]       = global_config['cli']['port']       || "443"
        @config[:api_prefix] = global_config['cli']['api_prefix'] || "/pulp/api" rescue "/pulp/api"
        @config[:verify_ssl] = global_config['cli']['verify_ssl'] || true
        @config[:dry_run]    = global_config['cli']['dry_run']    || false
        @root_config[:username] = root_config['cli']['username']  || "admin"
        @root_config[:password] = root_config['cli']['password']  || "password"
        @config.merge!(@root_config)
      end

      def get_all(repo_type=nil,instance_type=nil)
        case instance_type
          when 'repository'
            instance = 'repositories'
          when 'remote'
            instance = 'remotes'
          when 'publication'
            instance = 'publications'
        end

        if repo_type
          repos = request_api("/v3/#{instance}/#{repo_type}/#{repo_type}/")
        else
          repos = request_api("/v3/#{instance}/")
        end

        if repos.nil?
          return []
        else
          repos['results']
        end

      end

      def get_info(name,instance_type,repo_type)
        case instance_type
          when 'repository'
            instance = 'repositories'
          when 'remote'
            instance = 'remotes'
          when 'publication'
            instance = 'publications'
        end

        raise '[get_info] name should never be nil.' unless name and name != ''
        info = request_api("/v3/#{instance}/#{repo_type}/#{repo_type}/?name=#{name}")
        info['results'][0] rescue []
      end

      def get_href(name,instance_type,repo_type)
        case instance_type
          when 'repository'
            instance = 'repositories'
          when 'remote'
            instance = 'remotes'
          when 'publication'
            instance = 'publications'
        end

        raise '[get_href] name, instance_type or repo_type should never be nil.' unless name and name != '' and instance_type and repo_type
        info = request_api("/v3/#{instance}/#{repo_type}/#{repo_type}/?name=#{name}")
        if info.nil? or info['results'].empty?
          return nil
        else
          info['results'][0]['pulp_href']
        end
      end

      private

      def parse_config(path)
        settings = {}

        if File.file?(path)
          begin
            file = File.new(path, "r")
            while (line = file.gets)
              if line =~ /(^#|^\s+$)/
                # comment
              elsif line =~ /^\[(.+)\]$/
                section = $1.strip
                settings[section.strip] = Hash.new
              elsif line =~ /^[^\[]/
                key, value = line.split('=')
                settings[section.strip][key.strip] = value.gsub('"','').strip
              else
                raise "I don't understand this line: #{line}"
              end
            end
            file.close
          rescue => err
            Puppet::Util::Warnings.warnonce("Exception: #{err}")
          end
        end

        settings
      end

      def request_api(path,action='get')
        begin
          uri = URI("#{@config[:base_url]}:#{@config[:port]}#{@config[:api_prefix]}#{path}")

          req = Net::HTTP::Get.new(uri.request_uri)
          req.basic_auth @config[:username], @config[:password]
          resp = connection.request req
          if resp.code == '200'
            JSON.parse(resp.body)
          elsif resp.code == '404'
            nil
          else
            raise Puppet::Error, "https request returned code #{resp.code}. Connection details: url=#{uri}"
          end
        rescue Exception => e
          Puppet::Util::Warnings.warnonce("https request threw exception #{e.message}. Connection details: url=#{uri}")
        end
      end

      def connection
        unless @conn

          uri = URI("#{@config[:base_url]}:#{@config[:port]}")

          @conn = Net::HTTP.new(uri.host,uri.port)
          @conn.use_ssl = true

          # conn.ca_file = '/etc/pki/ca-trust/source/anchors/puppet_ca.pem'
          if [true, 'True', 1].include? @config[:verify_ssl]
            @conn.verify_mode = OpenSSL::SSL::VERIFY_PEER
          else
            @conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
        end

        @conn
      end

    end
  end
end
