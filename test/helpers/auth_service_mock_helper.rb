########################################################
#
# This module provides functionality to define some mocked
# behavior of the auth API of the downstream auth service
#
########################################################
module AuthServiceMockHelper

  ###########################################################################
  #
  # Register mock behavior to trigger 'Normal' auth service behavior
  #
  # While this behavior is registered, do all the testing of the authfilter
  # where normal auth service behavior is expected
  #
  ###########################################################################
  def auth_mock_normal

    auth_svc_base_url = Rails.application.config.authsvc_base_url
    auth_url = "#{auth_svc_base_url}/user/auth"

    #
    # Mock the successful auth service response
    # 200 - and the response echoes the auth token in JSON
    #
    auth_request_good_headers = {'Content-Type' => 'application/json', 'X-User-Token' => 'GOOD', 'Accept' => 'application/json'}
    auth_success_response = { :id => 1, :email => 'integration@test.com', :authentication_token => 'GOOD'}.to_json

    stub_request(:get, auth_url).with(:headers => auth_request_good_headers).to_return {
        |request| {:status => 200, :body => auth_success_response}
    }

    #
    # Mock the  auth service response
    # 401 Not authorized
    #
    auth_request_bad_headers = {'Content-Type' => 'application/json', 'X-User-Token' => 'BAD', 'Accept' => 'application/json'}
    auth_failure_response = {:error => I18n.t("401response")}.to_json

    stub_request(:get, auth_url).with(:headers => auth_request_bad_headers).to_return {
        |request| {:status => 401, :body => auth_failure_response}
    }
  end


  ###########################################################################
  #
  # Register an abnormal mock service behavior where the 200 response
  # is not echoing the user's auth token. This should trigger a 500 response
  # from our authentication filter.
  #
  ###########################################################################
  def auth_mock_good_gives_200_response_missing_token

    auth_svc_base_url = Rails.application.config.authsvc_base_url
    auth_url = "#{auth_svc_base_url}/user/auth"

    #
    # Mock the successful auth service response
    # 200 - BUT the response does not echoe the auth token in JSON
    #
    auth_request_good_headers = {'Content-Type' => 'application/json', 'X-User-Token' => 'GOOD', 'Accept' => 'application/json'}
    auth_success_response = { :id => 1, :email => 'integration@test.com', :authentication_token => 'GOODPlusStuff'}.to_json

    stub_request(:get, auth_url).with(:headers => auth_request_good_headers).to_return {
        |request| {:status => 200, :body => auth_success_response}
    }
  end

  ###########################################################################
  #
  # Register an abnormal mock service behavior where the auth service gives
  # a 500 response. This should a 500 response from our authentication filter.
  #
  ###########################################################################
  def auth_mock_good_gives_500_response

    auth_svc_base_url = Rails.application.config.authsvc_base_url
    auth_url = "#{auth_svc_base_url}/user/auth"

    #
    # Mock the successful auth service response
    # 200 - BUT the response does not echoe the auth token in JSON
    #
    auth_request_good_headers = {'Content-Type' => 'application/json', 'X-User-Token' => 'GOOD', 'Accept' => 'application/json'}
    auth_500_response = {:error => I18n.t("500response_internal_server_error")}.to_json

    stub_request(:get, auth_url).with(:headers => auth_request_good_headers).to_return {
        |request| {:status => 200, :body => auth_500_response}
    }
  end

end