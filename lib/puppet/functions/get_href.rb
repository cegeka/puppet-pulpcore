#require File.expand_path(File.join(File.dirname(__FILE__), '../util', 'pulpcore_util'))
require_relative '../util/pulpcore_util'

module PuppetX
  module Pulpcore
  end
end

# @summary
#   Get the href of an object in Pulp
#
Puppet::Functions.create_function(:'get_href') do
  # @param name
  #   The resource name
  #
  # @param instance_type
  #   The instance type [repository,remote,distribution]
  #
  # @param repository_type
  #   The repository type [rpm,docker,..]
  #
  # @return [String]
  #   The object HREF string
  #
  dispatch :getobject do
    required_param 'Variant[String, Sensitive[String]]', :name
    required_param 'Variant[String, Sensitive[String]]', :instance_type
    required_param 'Variant[String, Sensitive[String]]', :repo_type
    return_type 'String'
  end

  def getobject(name,instance_type,repo_type)
    if name.is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive)
       name = name.unwrap
    end
    if instance_type.is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive)
      type = instance_type.unwrap
    end
    if repo_type.is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive)
      type = repo_type.unwrap
    end

    begin
      if defined?(Puppet::Util::PulpcoreUtil) != 'constant' && Puppet::Util::PulpcoreUtil.class != Class
        raise Puppet::Error, 'Class Puppet::Util::PulpcoreUtil doesn\'t exist'
      end
      item = Puppet::Util::PulpcoreUtil.new
    rescue => err
      Puppet::Util::Warnings.warnonce("Error while creating PulpcoreUtil: #{err}")
      return "pending_pulpcore_util for: #{name} #{instance_type}/#{repo_type}"
    end

    begin
      href = item.get_href(name,instance_type,repo_type)
    rescue
      return "href_lookup_error for: #{name} #{instance_type}/#{repo_type}"
    end

    if href.nil?
      return "href_undefined for: #{name} #{instance_type}/#{repo_type}"
    else
      return href
    end

  end
end
