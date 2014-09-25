ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock'
include WebMock::API
require 'rest-client'

require 'config/auth_service_credentials_util'
require 'config/test_settings_util'

require 'helpers/auth_service_mock_helper'
require 'helpers/auth_service_real_helper'
require 'helpers/base_integration_test'
require 'integration/local_integration_test'
require 'remote/remote_integration_test'

require 'controllers/deployments_controller_tests'

class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...
end
