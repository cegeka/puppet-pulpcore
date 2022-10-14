require_relative '../util/pulpcore_util.rb'
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
      item = Puppet::Util::PulpcoreUtil.new
    rescue
      return 'undefined'
    end

    begin
      href = item.get_href(name,instance_type,repo_type)
    rescue
      return 'undefined'
    end

    if href.nil?
      return 'undefined'
    else
      return href
    end

  end
end
