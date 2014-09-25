module DeploymentsControllerTests

  def check_204_for_status_request
    my_headers = create_headers("GET")
    response = do_get_with_headers("/", my_headers)
    assert_response_code(response, 204)
  end

end