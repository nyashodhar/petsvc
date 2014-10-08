module AuthenticationHelper

  ########################################################################
  # This method is in use for all controller actions that require
  # authentication.
  #
  # If something goes wrong this method will render one of the two
  # following errors back to the client.
  #
  # 401:
  # - The request did not include an auth token
  # - Auth service found a sign-in for the auth token, but it's expired
  # - Auth service found a sign-in for the auth token, but it was an
  #   external user when internal user was required.
  # - Auth service did not find any sign-in for given token
  #
  # 500:
  # - The auth service request didn't get any response
  # - Auth service gave a 4xx other than 401 or a 5xx response
  # - Auth service gave a 200 response, but the response body was not valid
  #
  # If the auth service gives a 200 response that passes a validation
  # check we will conclude that the user's sign-in is valid and control
  # will be allowed to reach the controller action.
  ########################################################################
  def ensure_authenticated

    token = request.headers['X-User-Token']
    if(token.blank?)
      logger.error "ensure_authenticated(): No auth token found in request"
      render :status => 401, :json => {:error => I18n.t("401response")}
      return
    end

    auth_svc_base_url = Rails.application.config.authsvc_base_url
    auth_url = "#{auth_svc_base_url}/user/auth"

    # Note: Without setting accept header here, we will get an XML response
    auth_request_headers = {'Content-Type' => 'application/json', 'X-User-Token' => token, 'Accept' => 'application/json'}

    logger.debug "ensure_authenticated(): Doing GET #{auth_url} (headers = #{auth_request_headers})"

    begin

      auth_service_response = RestClient.get(auth_url, auth_request_headers)
      auth_service_response_hash = JSON.parse(auth_service_response)

      if(auth_service_response_hash['authentication_token'].blank? || !auth_service_response_hash['authentication_token'].eql?(token))
        logger.error "ensure_authenticated(): Auth service gave success response but the user's token could not be found in the response. This should NEVER happen!. CODE: #{auth_service_response.code}, RESPONSE: #{auth_service_response} (auth_url = #{auth_url}, auth_request_headers = #{auth_request_headers})"
        render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
        return
      end

      # Make the id of the authenticated user available in controller instance variables:
      authenticated_email = auth_service_response_hash['email']
      authenticated_id = auth_service_response_hash['id']
      set_authentication_info(authenticated_id, authenticated_email)

      # SUCCESS - The user is authenticated
      logger.info "ensure_authenticated(): Auth service success. CODE: #{auth_service_response.code}, EMAIL: #{authenticated_email}, USERID: #{auth_service_response_hash['id']}"
      return

    rescue => e

      if(defined? e.response)
        if(e.response.code == 401)
          logger.error "ensure_authenticated(): Not authorized. CODE: #{e.response.code}, RESPONSE: #{e.response}"
          render :status => 401, :json => {:error => I18n.t("401response")}
          return
        end
        logger.error "ensure_authenticated(): Unexpected auth service response. CODE: #{e.response.code}, RESPONSE: #{e.response} (auth_url = #{auth_url}, auth_request_headers = #{auth_request_headers})"
        render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
        return
      else
        logger.error "ensure_authenticated(): Unexpected error! auth_url = #{auth_url}, auth_request_headers = #{auth_request_headers}, error = #{e}"
        render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
        return
      end

    end
  end

end
