require File.expand_path('../pulp_util', __FILE__)

module PuppetX
  module Pulpcore
  end
end

class PuppetX::Pulpcore::RemoteProvider < Puppet::Provider
  # Implementers must:
  #
  # # Set the repo type (iso, puppet, rpm)
  # def self.repo_type
  #   'x'
  # end
  #
  # def self.get_resource_properties(repo_id)
  #   # Get a hash of the current repo
  # end
  #
  # def params_hash
  #   # Convert resource to a hash of params
  # end

  def initialize(resource={})
    super(resource)
    @property_flush = {}
  end

  def self.instances
    @pulp = Puppet::Util::PulpcoreUtil.new
    @pulp.get_all("#{repo_type}",'remote').map { |remote|
      # puts remote
      new(get_resource_properties(remote['name'],repo_type))
    }
  end

  def exists?
    #@property_hash[:ensure] == :present
    # puts "remote exists"

    # puts "property hash:"
    # puts @property_hash
    # puts ""
    # puts "remotes loop:"
    @pulp = Puppet::Util::PulpcoreUtil.new
    @pulp.get_all("#{self.class.repo_type}",'remote').map { |remote|
      # puts remote
      # puts ""
      # puts remote['name']
      # puts ""
      # puts @property_hash[:name]
      # puts ""
      if remote['name'] == @property_hash[:name]
        # puts "inside if, return true"
        return true
      end
    }

    # puts "return false"
    return false
  end

  def create
    @property_flush[:ensure] = :present
    # puts "must create"
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def self.prefetch(resources)
    remotes = instances
    return if remotes.nil?
    resources.each do |name, resource|
      provider = remotes.find { |remote| remote.name == name }
      resource.provider = provider if provider
    end
  end

  def hash_to_params(params_hash)
    params = []
    params_hash.each do |k, v|
      if v.kind_of?(Array)
        params << [k, v.join(',')]
      elsif v.kind_of?(Hash)
        v.to_a.each do |pair|
          params << [k, pair.join('=')]
        end
      elsif v.nil?
        params << [k]
      elsif !v.nil?
        params << [k, v]
      end
    end
    params
  end

  def flush
    if @property_flush[:ensure] == :absent
      # puts "flush: delete"
      action = 'delete'
      params = []
    elsif @property_flush[:ensure] == :present
      # puts "flush: create"
      action = 'create'
      params = hash_to_params(params_hash)
    else
      # puts "flush: update"
      action = 'update'
      params = hash_to_params(params_hash)
    end

    arr = [self.class.repo_type, 'remote', action, '--name', resource[:name], params]
    pulp_admin(arr.flatten)

    # Collect the resources again once they've been changed (that way `puppet
    # resource` will show the correct values after changes have been made).
    @property_hash = self.class.get_resource_properties(resource[:name])
  end
end