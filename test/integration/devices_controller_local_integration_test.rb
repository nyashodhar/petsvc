require 'test_helper'

class DevicesControllerLocalIntegrationTest < LocalIntegrationTest

  #include DevicesControllerTests

  #
  # POST /device
  #

  test "POST Device - API is protected by auth filter for internal users" do
    check_api_is_protected("POST", "device", {:device_id => '984987287987322233'}.to_json, true)
  end

end