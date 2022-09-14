require File.expand_path('../pulp_util', __FILE__)

module PuppetX
  module Pulpcore
  end
end

class PuppetX::Pulpcore::RepoProvider < Puppet::Provider
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
    @pulp.get_all("#{repo_type}",'repository').map { |repo|
      new(get_resource_properties(repo['name'],repo_type))
    }
  end

  def exists?
    @property_hash[:ensure] == :present
    puts "repo exists start-------"

    @pulp = Puppet::Util::PulpcoreUtil.new
    @pulp.get_all("#{self.class.repo_type}",'repository').map { |repo|
      puts repo
      puts ""
      puts repo['name']
      puts ""
      puts @property_hash[:name]
      puts ""
      if repo['name'] == @property_hash[:name]
        puts "inside if, return true"
        return true
      end
    }

    puts "return false"
    puts "repo exists end-------"
    return false
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def self.prefetch(resources)
    # puts "resources -------"
    # puts resources
    # puts "------"

    repos = instances
    puts "repos -------"
    puts repos
    puts "------"

    return if repos.nil? or repos.empty?

    puts "prefetch start"
    puts repos
    puts "------"
    

    resources.each do |name, resource|
      provider = repos.find { |repo| repo.name == name }

      puts provider
      puts ""
      
      resource.provider = provider if provider
    end
    puts "prefetch end"
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
    puts "repo flush start------"
    if @property_flush[:ensure] == :absent
      puts "in delete"
      action = 'delete'
      params = []
    elsif @property_flush[:ensure] == :present
      puts "in create"
      action = 'create'
      params = hash_to_params(params_hash)
    else
      puts "in update"
      action = 'update'
      params = hash_to_params(params_hash)
    end

    puts "end if"
    arr = [self.class.repo_type, 'repository', action, '--name', resource[:name], params]
    puts "before flatten"
    pulp_admin(arr.flatten)
    puts "after flatten"
    # Collect the resources again once they've been changed (that way `puppet
    # resource` will show the correct values after changes have been made).
    @property_hash = self.class.get_resource_properties(resource[:name])
    puts "repo flush end------"
  end
end
