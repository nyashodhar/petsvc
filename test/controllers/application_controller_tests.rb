module ApplicationControllerTests

  #
  # Test that requests for which the URL path could not be mapped to any
  # controller get a proper 404 formatted response
  #
  def check_404_for_url_with_no_mapping

    # Do request as JSON client
    my_request_headers = create_headers("GET")
    response = do_get_with_headers("profile/foobardfgd", my_request_headers)

    assert_response_code(response, 404)
    content_type_in_response = get_content_type(response)
    assert(content_type_in_response.downcase.include?("application/json"))

    my_response = JSON.parse(response.body)
    assert_not_nil(my_response["error"])
    assert(my_response["error"].eql?("Resource not found"))

    # Do request as HTML client
    my_request_headers = {'Content-Type' => 'text/html'}
    response = do_get_with_headers("profile/foobardfgd", my_request_headers)
    assert_response_code(response, 404)

    content_type_in_response = get_content_type(response)
    assert(content_type_in_response.downcase.include?("application/json"))

    my_response = JSON.parse(response.body)
    assert_not_nil(my_response["error"])
    assert(my_response["error"].eql?("Resource not found"))

  end

end