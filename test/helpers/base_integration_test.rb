class BaseIntegrationTest < ActionDispatch::IntegrationTest

  @@auth_service_credentials = AuthServiceCredentialsUtil.new
  @@test_settings_util = TestSettingsUtil.new

  setup do
    @email = @@auth_service_credentials.get_username('1')
    @password = @@auth_service_credentials.get_password('1')
    @auth_svc_base_url = @@test_settings_util.get_auth_service_url
  end

  def exercise_api(http_method, api_uri, request_body, my_headers)

    if(http_method.eql?("POST"))
      return do_post_with_headers(api_uri, request_body, my_headers)
    end

    if(http_method.eql?("PUT"))
      return do_put_with_headers(api_uri, request_body, my_headers)
    end

    if(http_method.eql?("GET"))
      return do_get_with_headers(api_uri, my_headers)
    end
  end

  def create_str_with_len(length)
    my_string = ""
    length.times do ||
      my_string = "#{my_string}X"
    end
    return my_string
  end

  def validate_http_method(http_method)
    if(http_method.blank?)
      raise 'Parameter http_method not specified'
    end

    if(!(http_method.eql?('GET') || http_method.eql?('POST') || http_method.eql?('PUT')))
      raise 'Invalid value #{http_method} for http_method.'
    end
  end

end