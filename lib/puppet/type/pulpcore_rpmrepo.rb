require 'puppet/property/boolean'
# curl -E ~/.pulp/user-cert.pem "https://$(hostname)/pulp/api/v3/repositories/?name=epel_el6" | python -mjson.tool

Puppet::Type.newtype(:pulpcore_rpmrepo) do
  @doc = <<-EOT
    doc
  EOT

  autorequire(:file) do
    [
      self[:conf_file],
      self[:name],
      self[:description],
      self[:remote],
      self[:metadata_checksum_type],
      self[:package_checksum_type],
      self[:gpgcheck],
      self[:repo_gpgcheck],
      self[:autopublish],
      self[:retain_repo_versions],
      self[:retain_package_versions],
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
    desc "name: uniquely identifies the rpm repo"
  end

  newparam(:conf_file, :parent => Puppet::Parameter::Path) do
    desc "path to pulp-admin's config file. Defaults to /root/.config/pulp/cli.toml"
    defaultto('/root/.config/pulp/cli.toml')
  end

  newproperty(:description) do
    desc "user-readable description (may contain i18n characters)"
  end

  newproperty(:remote) do
    desc "Name of the external source repository to sync"
    defaultto('unknown')
  end

  newproperty(:metadata_checksum_type) do
    desc "Checksum type of repository metadata"
  end

  newproperty(:package_checksum_type) do
    desc "Checksum type of packages"
  end

  newproperty(:gpgcheck) do
    desc "GPG checksum of packages"

    munge { |value| @resource.munge_boolean_to_symbol(value) }
  end

  newproperty(:repo_gpgcheck) do
    desc "GPG checksum of repository"

    munge { |value| @resource.munge_boolean_to_symbol(value) }
  end

  newproperty(:autopublish) do
    desc "Auto publish repository"

    munge { |value| @resource.munge_boolean_to_string(value) }
  end

  newproperty(:retain_repo_versions) do
    desc "Amount of repository versions"
    newvalues(/^\d+$/)
    munge do |value|
      Integer(value)
    end
    defaultto 3
  end

  newproperty(:retain_package_versions) do
    desc "Amount of package versions"
    newvalues(/^\d+$/)
    munge do |value|
      Integer(value)
    end
    defaultto 3
  end
end
