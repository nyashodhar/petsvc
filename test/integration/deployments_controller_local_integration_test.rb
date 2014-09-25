require 'test_helper'

class DeploymentsControllerLocalIntegrationTest < LocalIntegrationTest

  include DeploymentsControllerTests

  test "Check 204 for status request" do
    check_204_for_status_request
  end
end