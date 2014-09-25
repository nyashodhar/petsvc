module CatchJsonParseErrorsTests

  #
  # Test that requests with invalid json are handled properly
  # Send a request with invalid JSON, you should get a 400 JSON response
  #
  def check_invalid_json_handling

    invalid_json = '{ not good json'

    good_auth_token = get_good_auth_token
    profile_update_headers = create_headers_with_auth_token("POST", good_auth_token)
    response = do_post_with_headers("profile", invalid_json, profile_update_headers)
    assert_response_code(response, 400)

    the_response = JSON.parse(response.body)
    assert_not_nil(the_response["error"])
    assert(the_response["error"].eql?("There was a problem in your JSON"))
  end

end