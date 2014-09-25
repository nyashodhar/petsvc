include AuthServiceRealHelper

class RemoteIntegrationTest < BaseIntegrationTest

  setup do
    WebMock.allow_net_connect!
    @target_svc_url = @@test_settings_util.get_target_service_url
  end

  ##########################################################
  #
  # Performs all the testing needed to verify that the
  # auth filter protection is applied correctly for the
  # API specified.
  #
  ##########################################################
  def check_api_is_protected(http_method, api_uri, request_body)

    validate_http_method(http_method)

    my_headers = create_headers_with_auth_token(http_method, api_uri)

    #
    # Do checking to check 401 is given under normal circumstances
    #

    # If auth token is missing, the filter should give a 401..
    my_headers.delete('X-User-Token')
    response = exercise_api(http_method, api_uri, request_body, my_headers)
    assert_response_code(response, 401)

    # If auth token is bad, there should be a downstream 401 and the filter should pass on the 401
    my_headers['X-User-Token'] = "BAD"
    response = exercise_api(http_method, api_uri, request_body, my_headers)
    assert_response_code(response, 401)

    STDOUT.write "Good news: The API \'#{http_method} #{api_uri}\' passed auth tests.\n"
  end


  def create_headers(http_method)
    return {'Content-Type' => 'application/json', 'Accept' => 'application/json' }
  end

  def create_headers_with_auth_token(http_method, auth_token)
    return {'Content-Type' => 'application/json', 'Accept' => 'application/json', 'X-User-Token' => auth_token }
  end

  def get_content_type(response)
    return response.headers[:content_type]
  end

  def do_get_with_headers(api_uri, my_headers)
    begin
      return RestClient.get("#{@target_svc_url}/#{api_uri}", my_headers)
    rescue => e
      if(defined? e.response)
        return e.response
      else
        raise "do_get_with_headers_remote(): Unexpected error! No response for url = #{@target_svc_url}/#{api_uri}, headers = my_headers, error = #{e}"
      end
    end
  end

  def do_put_with_headers(api_uri, my_body, my_headers)
    begin
      return RestClient.put("#{@target_svc_url}/#{api_uri}", my_body, my_headers)
    rescue => e
      if(defined? e.response)
        return e.response
      else
        raise "do_put_with_headers_remote(): Unexpected error! No response for url = #{@target_svc_url}/#{api_uri}, body = #{my_body}, headers = my_headers, error = #{e}"
      end
    end
  end

  def do_post_with_headers(api_uri, my_body, my_headers)
    begin
      return RestClient.post("#{@target_svc_url}/#{api_uri}", my_body, my_headers)
    rescue => e
      if(defined? e.response)
        return e.response
      else
        raise "do_post_with_headers_remote(): Unexpected error! No response for url = #{@target_svc_url}/#{api_uri}, body = #{my_body}, headers = my_headers, error = #{e}"
      end
    end
  end

  def assert_response_code(response, expected_response_code)
    if(response == nil)
      raise "Can't assert response code in response, response is blank: #{response}\n"
    end
    if(!response.code.to_s.eql?(expected_response_code.to_s))
      raise "Unexpected response code. Expected response code: #{expected_response_code}, actual response code: #{response.code}\n"
    end
  end

  def get_good_auth_token(internal_user)
    if(internal_user)
      return get_token_from_real_login(@internal_user_email, @internal_user_password, @auth_svc_base_url)
    else
      return get_token_from_real_login(@external_user_email, @external_user_password, @auth_svc_base_url)
    end
  end

end