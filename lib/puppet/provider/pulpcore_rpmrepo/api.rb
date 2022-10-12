require File.join(File.dirname(__FILE__), '../../util', 'repo_provider')

Puppet::Type.type(:pulpcore_rpmrepo).provide(:api, :parent => Puppet::Provider::RepoProvider) do
  commands :pulp_admin => '/usr/bin/pulp'

  mk_resource_methods

  def self.repo_type
    'rpm'
  end

  def self.get_resource_properties(repo_name,repo_type=self.repo_type)
    hash = {}

    repo = @pulp.get_info(repo_name,'repository',repo_type)

    unless repo
      hash[:ensure] = :absent
      return hash
    end

    hash[:name] = repo_name
    hash[:ensure] = :present
    hash[:provider] = :pulpcore_rpmrepo
    hash[:description] = repo['description']
    hash[:remote] = repo['remote']
    hash[:autopublish] = repo['autopublish'].to_s
    hash[:retain_repo_versions] = repo['retain_repo_versions']
    hash[:retain_package_versions] = repo['retain_package_versions']
    hash[:metadata_checksum_type] = repo['metadata_checksum_type']
    hash[:package_checksum_type] = repo['package_checksum_type']
    hash[:gpgcheck] = repo['gpgcheck']
    hash[:repo_gpgcheck] = repo['repo_gpgcheck']

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
    Puppet.debug "Repo properties: #{hash.inspect}"

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
    params.merge!({ '--description' => resource[:description] }) if resource[:description]
    params.merge!({ '--retain-package-versions' => resource[:retain_package_versions] }) if resource[:retain_package_versions]
    params.merge!({ '--retain-repo-versions' => resource[:retain_repo_versions] }) if resource[:retain_repo_versions]
    params.merge!({ '--remote' => resource[:remote] }) if resource[:remote]
    params.merge!({ '--metadata-checksum-type' => resource[:metadata_checksum_type] }) if resource[:metadata_checksum_type]
    params.merge!({ '--package-checksum-type' => resource[:package_checksum_type] }) if resource[:package_checksum_type]
    params.merge!({ '--gpgcheck' => resource[:gpgcheck] }) if resource[:gpgcheck]
    params.merge!({ '--repo-gpgcheck' => resource[:repo_gpgcheck] }) if resource[:repo_gpgcheck]
    params.merge!({ '--autopublish' => nil }) if resource[:autopublish]
    params.merge!({ '--no-autopublish' => nil }) if ! resource[:autopublish]
    params
  end
end
