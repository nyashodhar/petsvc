require 'test_helper'

class CatchJsonParseErrorsRemoteIntegrationTest < RemoteIntegrationTest

  include CatchJsonParseErrorsTests

  test "Verify invalid JSON handling" do
    check_invalid_json_handling
  end

end