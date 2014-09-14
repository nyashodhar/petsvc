require 'test_helper'

class DeploymentsControllerIntegrationTest < ActionDispatch::IntegrationTest

  test "Check 204 for status request" do
    my_headers = {'Content-Type' => 'application/json'}
    get "/", nil, my_headers
    assert_response :no_content
  end
end