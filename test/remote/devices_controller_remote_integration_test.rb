require 'test_helper'

class DevicesControllerLocalIntegrationTest < RemoteIntegrationTest

  #include DevicesControllerTests

  #
  # POST /device
  #

  test "POST Device - API is protected by auth filter for internal users" do
    check_api_is_protected("POST", "device", {:serial => '984987287987322233'}.to_json, true)
  end

end