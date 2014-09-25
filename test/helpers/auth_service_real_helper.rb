module AuthServiceRealHelper

  ######################################################
  #
  # Obtain auth token from real auth service
  #
  ######################################################
  def get_token_from_real_login(email, password, auth_svc_base_url)

    auth_url = "#{auth_svc_base_url}/user/auth"
    auth_request_headers = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}

    login_user_hash = {:email => email, :password => password}
    login_body = {:user => login_user_hash}

    #STDOUT.write "get_token_from_real_login(): Doing GET #{auth_url} (headers = #{auth_request_headers}) - body #{login_body}\n"

    begin

      auth_service_response = RestClient.post(auth_url,login_body, auth_request_headers)
      auth_service_response_hash = JSON.parse(auth_service_response)

      if(auth_service_response_hash['authentication_token'].blank?)
        raise "get_token_from_real_login(): Auth service login gave success response but no token was found in the response. CODE: #{auth_service_response.code}, RESPONSE: #{auth_service_response} (auth_url = #{auth_url}, auth_request_headers = #{auth_request_headers}, login_body = #{login_body})"
      end

      #STDOUT.write "get_token_from_real_login(): Auth service login successful. CODE: #{auth_service_response.code}, USERID: #{auth_service_response_hash['id']}\n"
      return auth_service_response_hash['authentication_token']

    rescue => e

      if(defined? e.response)
        if(e.response.code == 401)
          raise "get_token_from_real_login(): Not authorized. CODE: #{e.response.code}, RESPONSE: #{e.response}"
        end
        raise "get_token_from_real_login(): Unexpected auth service response. CODE: #{e.response.code}, RESPONSE: #{e.response} (auth_url = #{auth_url}, auth_request_headers = #{auth_request_headers})"
      else
        raise "get_token_from_real_login(): Unexpected error! auth_url = #{auth_url}, auth_request_headers = #{auth_request_headers}, error = #{e}"
      end
    end
  end


end