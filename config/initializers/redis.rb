
redis_host = Rails.application.config.redis_host
redis_port = Rails.application.config.redis_port
redis_password_required = Rails.application.config.redis_password_required
redis_password = Rails.application.config.redis_password

begin

  redis_connection_args = {:host => redis_host, :port => redis_port}

  if(redis_password_required)
    if(redis_password.blank?)
      STDOUT.write "=> ERROR in Redis initializer: Password in required, but no password is set in config. Make sure redis_password is set in environment config\n"
      exit
    end
    redis_connection_args[:password] = redis_password
    password_setup = "Password was required"
  else
    password_setup = "Password was not required"
  end

  $redis = Redis.new(redis_connection_args)

  ping_result = $redis.ping
  STDOUT.write "=> Redis initializer: Created redis client for #{redis_host}:#{redis_port} - #{password_setup} - Ping result (#{ping_result})\n"
rescue => e
  STDOUT.write "=> ERROR in Redis initializer: Error when creating redis client for #{redis_host}:#{redis_port} - #{password_setup} - Error: #{e.inspect}\n"
  exit
end