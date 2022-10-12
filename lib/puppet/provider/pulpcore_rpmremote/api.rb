require File.join(File.dirname(__FILE__), '../../util', 'remote_provider')

Puppet::Type.type(:pulpcore_rpmremote).provide(:api, :parent => Puppet::Provider::RemoteProvider) do
  commands :pulp_admin => '/usr/bin/pulp'

  mk_resource_methods

  def self.repo_type
    'rpm'
  end

  # special getter methods for parameters that receive a file and write the content
  [:ca_cert,
   :client_cert,
   :client_key,
  ].each do |method|
    method = method.to_sym
    define_method method do
      #if resource[method] && File.read(resource[method]) == @property_hash[method]
      if resource[method] && File.read(resource[method])
        resource[method]
      else
        nil
      end
    end
  end

  def self.get_resource_properties(remote_name,repo_type=self.repo_type)
    hash = {}

    remote = @pulp.get_info(remote_name,'remote',repo_type)
    unless remote
      hash[:ensure] = :absent
      return hash
    end

    hash[:name] = remote_name
    hash[:ensure] = :present
    hash[:provider] = :pulpcore_rpmremote
    hash[:url] = remote['url']
    hash[:username] = remote['username']
    hash[:password] = remote['password']
    hash[:ca_cert] = remote['ca_cert']
    hash[:client_cert] = remote['client_cert']
    hash[:client_key] = remote['client_key']
    hash[:tls_validation] = remote['tls_validation'].to_s
    hash[:proxy_url] = remote['proxy_url']
    hash[:proxy_username] = remote['proxy_username']
    hash[:proxy_password] = remote['proxy_password']
    hash[:policy] = remote['policy']
    hash[:total_timeout] = remote['total_timeout']
    hash[:connect_timeout] = remote['connect_timeout']
    hash[:sock_connect_timeout] = remote['sock_connect_timeout']
    hash[:sock_read_timeout] = remote['sock_read_timeout']
    hash[:rate_limit] = remote['rate_limit']
    hash[:sles_auth_token] = remote['sles_auth_token']
    hash[:download_concurrency] = remote['download_concurrency']

    hash = Hash[hash.map do |k, v|
      case v
      when true
        [k, :true]
      when false
        [k, :false]
      else
        [k, v]
      end
    end]
    Puppet.debug "Remote properties: #{hash.inspect}"

    hash
  end

  def being_created?
    # If we are updating a resource, @property_hash will have already been populated by 'instances' (and updated by property setters).
    # If the resource is being created, @property_hash will be empty
    @property_hash.empty?
  end

  def params_hash
    # Some properties have defaults that use to be set in the type definition.
    # We actually should only use these defaults when creating new resources, so the defaults are now in the provider (in this method).
    params = {}
    params.merge!({ '--url' => resource[:url] }) if resource[:url]
    params.merge!({ '--ca-cert' => '@'+resource[:ca_cert] }) if resource[:ca_cert]
    params.merge!({ '--client-cert' => '@'+resource[:client_cert] }) if resource[:client_cert]
    params.merge!({ '--client-key' => '@'+resource[:client_key] }) if resource[:client_key]
    params.merge!({ '--connect-timeout' => resource[:connect_timeout] }) if resource[:connect_timeout]
    params.merge!({ '--download-concurrency' => resource[:download_concurrency] }) if resource[:download_concurrency]
    params.merge!({ '--username' => resource[:username] }) if resource[:username]
    params.merge!({ '--password' => resource[:password] }) if resource[:password]
    params.merge!({ '--proxy-url' => resource[:proxy_url] }) if resource[:proxy_url]
    params.merge!({ '--proxy-username' => resource[:proxy_username] }) if resource[:proxy_username]
    params.merge!({ '--proxy-password' => resource[:proxy_password] }) if resource[:proxy_password]
    params.merge!({ '--rate-limit' => resource[:rate_limit] }) if resource[:rate_limit]
    params.merge!({ '--sock-connect-timeout' => resource[:sock_connect_timeout] }) if resource[:sock_connect_timeout]
    params.merge!({ '--sock-read-timeout' => resource[:sock_read_timeout] }) if resource[:sock_read_timeout]
    params.merge!({ '--total-timeout' => resource[:total_timeout] }) if resource[:total_timeout]
    params.merge!({ '--tls-validation' => resource[:tls_validation] }) if resource[:tls_validation]
    params.merge!({ '--policy' => resource[:policy] }) if resource[:policy]
    params.merge!({ '--sles-auth-token' => resource[:sles_auth_token] }) if resource[:sles_auth_token]
    params
  end
end
