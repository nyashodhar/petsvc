
include AuthServiceMockHelper
include AuthServiceRealHelper

class LocalIntegrationTest < BaseIntegrationTest

  setup do
    @mock_auth_service = @@test_settings_util.get_mock_auth_svc_in_tests
    if(@mock_auth_service)
      WebMock.disable_net_connect!
      auth_mock_normal(@external_user_email)
    else
      WebMock.allow_net_connect!
    end
  end

  ##########################################################
  #
  # Performs all the testing needed to verify that the
  # auth filter protection is applied correctly for the
  # API specified.
  #
  ##########################################################
  def check_api_is_protected(http_method, api_uri, request_body, internal_user_required)

    validate_http_method(http_method)

    my_headers = create_headers_with_auth_token(http_method, "BAD")

    if(@mock_auth_service)
      auth_mock_normal(@external_user_email)
    end

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

    if(internal_user_required)
      #
      # If the auth token is good, but the authenticated user is an external user when an
      # internal was required, we should get a 401 from the filter
      #
      my_headers['X-User-Token'] = "GOOD"
      response = exercise_api(http_method, api_uri, request_body, my_headers)
      assert_response_code(response, 401)
    end

    if(@mock_auth_service)

      #
      # Do checking to check the filter is giving 500 error if the
      # auth service is not behaving as expected, this is only possible if the down
      # stream auth service is mocked..
      #

      # If the filter got 200 response from auth service that didn't echo the auth token,
      # then the filter should give 500 response
      auth_mock_good_gives_200_response_missing_token(@external_user_email)
      my_headers['X-User-Token'] = "GOOD"
      response = exercise_api(http_method, api_uri, request_body, my_headers)
      assert_response_code(response, 500)

      # If the filter got a 500 error from auth service, then the filter should give a 500 response
      auth_mock_good_gives_500_response
      my_headers['X-User-Token'] = "GOOD"
      response = exercise_api(http_method, api_uri, request_body, my_headers)
      assert_response_code(response, 500)

      # Leave the mocking in a normal state...
      auth_mock_normal(@external_user_email)
    end

    STDOUT.write "Good news: The API \'#{http_method} #{api_uri}\' passed auth tests.\n"
  end

  def create_headers(http_method)
    if(http_method.eql?("POST") || http_method.eql?("PUT"))
      return { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
    end
    if(http_method.eql?("GET"))
      return {'Content-Type' => 'application/json', 'Accept' => 'application/json' }
    end
  end

  def create_headers_with_auth_token(http_method, auth_token)
    if(http_method.eql?("POST") || http_method.eql?("PUT"))
      return { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'X-User-Token' => auth_token }
    end

    if(http_method.eql?("GET"))
      return {'Content-Type' => 'application/json', 'Accept' => 'application/json', 'X-User-Token' => auth_token }
    end
  end

  def do_get_with_headers(api_uri, my_headers)
    get api_uri, nil, my_headers
    return response
  end

  def do_post_with_headers(api_uri, my_body, my_headers)
    post api_uri, my_body, my_headers
    return response
  end

  def do_put_with_headers(api_uri, my_body, my_headers)
    put api_uri, my_body, my_headers
    return response
  end

  def get_good_auth_token(internal_user)
    if(!@mock_auth_service)
      if(internal_user)
        return get_token_from_real_login(@internal_user_email, @internal_user_password, @auth_svc_base_url)
      else
        return get_token_from_real_login(@external_user_email, @external_user_password, @auth_svc_base_url)
      end
    else
     return "GOOD"
    end
  end

  def assert_response_code(response, expected_response_code)
    assert_response expected_response_code
  end

  def get_content_type(response)
    return response.headers["Content-Type"]
  end

  #########################################
  # Create a hash containing the headers
  # to be used in a POST request
  #########################################
  def create_post_headers_with_auth_token(auth_token)
    validate_auth_token(auth_token)
    return { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'X-User-Token' => auth_token}
  end

  #########################################
  # Create a hash containing the headers
  # to be used in a GET request
  #########################################
  def create_get_headers_with_auth_token(auth_token)
    validate_auth_token(auth_token)
    return {'Content-Type' => 'application/json', 'Accept' => 'application/json', 'X-User-Token' => auth_token}
  end

  private

  def validate_auth_token(auth_token)
    if(auth_token.blank?)
      raise 'Parameter auth_token not specified'
    end

    if(auth_token.eql?('GOOD') && auth_token.eql?('BAD'))
      raise 'Invalid value #{auth_token} for auth_token. Value must be either \'GOOD\' or \'BAD\''
    end
  end

end