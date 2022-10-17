require 'puppet/property/boolean'
# curl -E ~/.pulp/user-cert.pem "https://$(hostname)/pulp/api/v3/remotes/?name=epel_el6" | python -mjson.tool

Puppet::Type.newtype(:pulpcore_rpmremote) do
  @doc = <<-EOT
    doc
  EOT

  autorequire(:file) do
    [
      self[:conf_file],
      self[:ca_cert],
      self[:client_cert],
      self[:client_key],
    ]
  end

  ensurable do
    desc <<-EOS
      Create/Remove pulp rpm repo.
    EOS

    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

    defaultto :present
  end

  def munge_boolean_to_symbol(value)
    # insync? doesn't work with actual booleans
    # see https://tickets.puppetlabs.com/browse/PUP-2368
    value = value.downcase if value.respond_to? :downcase

    case value
    when true, :true, 'true', :yes, 'yes'
      1
    when false, :false, 'false', :no, 'no'
      0
    else
      raise ArgumentError, 'expected a boolean value'
    end
  end

  def munge_boolean_to_string(value)
    # insync? doesn't work with actual booleans
    # see https://tickets.puppetlabs.com/browse/PUP-2368
    value = value.downcase if value.respond_to? :downcase

    case value
    when true, :true, 'true', :yes, 'yes'
      'true'
    when false, :false, 'false', :no, 'no'
      'false'
    else
      raise ArgumentError, 'expected a boolean value'
    end
  end

  newparam(:name, :namevar => true) do
    desc "name: uniquely identifies the rpm remote"
  end

  newparam(:conf_file, :parent => Puppet::Parameter::Path) do
    desc "path to pulp-admin's config file. Defaults to /root/.config/pulp/cli.toml"
    defaultto('/root/.config/pulp/cli.toml')
  end

  newproperty(:URL) do
    desc "Upstream URL"
  end

  newproperty(:username) do
    desc "Username to authenticate to the remote"
  end

  newproperty(:password) do
    desc "Password to authenticate to the remote"
  end

  newproperty(:ca_cert) do
    desc "CA certificate to check the remote"
  end

  newproperty(:client_cert) do
    desc "Client certificate to authenticate to the remote"
  end

  newproperty(:client_key) do
    desc "Client certificate key to authenticate to the remote"
  end

  newproperty(:tls_validation) do
    desc "TLS validation of the remote"
    defaultto :true
    #munge { |value| @resource.munge_boolean_to_symbol(value) }
  end

  newproperty(:proxy_url) do
    desc "Proxy URL to connect to the remote"
  end

  newproperty(:proxy_username) do
    desc "Proxy username"
  end

  newproperty(:proxy_password) do
    desc "Proxy password"
  end

  newproperty(:policy) do
    desc "Download policy"
    defaultto 'on_demand'
  end

  newproperty(:total_timeout) do
    desc "Maximum timeout"
    defaultto 300
  end

  newproperty(:connect_timeout) do
    desc "Connection timeout"
  end

  newproperty(:sock_connect_timeout) do
    desc "Socket timeout"
  end

  newproperty(:sock_read_timeout) do
    desc "Socket read timeout"
  end

  newproperty(:rate_limit) do
    desc "Rate limiting"
  end

  newproperty(:sles_auth_token) do
    desc "SLES remote Authentication token"
  end

  newproperty(:download_concurrency) do
    desc "Concurrent downloads"
    defaultto 3
  end

end
