#######################################################
#
# Utility class that allows access to the auth service
# user credential stored in the auth service credential
# yml file. The credentials are used in integration tests
#
#######################################################

class AuthServiceCredentialsUtil

  def initialize

    config_file = "#{Rails.root}/test/config/auth_service_credentials.yml"
    credentials_yaml = YAML::load_file(config_file)

    the_environment = Rails.env.to_str
    credentials_for_env = credentials_yaml[the_environment]

    #
    # Example of entry in this map will be:
    #
    #    {"1"=>{"u"=>"herrstrudel@gmail.com", "p"=>"Test1234"}}
    #

    @my_credentials = Hash.new

    credentials_for_env.keys.each { |userindex|
      @my_credentials[userindex.to_s] = credentials_for_env[userindex]
    }

    STDOUT.write "=> AuthServiceCredentialsUtil: Auth credentials loaded from #{config_file}\n"
  end

  def get_password(user_index)
    if(@my_credentials[user_index].blank?)
      return nil
    end
    return @my_credentials[user_index]['p']
  end

  def get_username(user_index)
    if(@my_credentials[user_index].blank?)
      return nil
    end
    return @my_credentials[user_index]['u']
  end
end