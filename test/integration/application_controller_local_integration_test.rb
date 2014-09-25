require 'test_helper'

class ApplicationControllerLocalIntegrationTest < LocalIntegrationTest

  include ApplicationControllerTests

  test "Verify 404 response for URL with no mapping - Always JSON response" do
    check_404_for_url_with_no_mapping
  end
end