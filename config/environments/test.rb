Rails.application.configure do

  # Settings specified here will take precedence over those in config/application.rb.

  # Config used for amazon s3 file uploads
  config.s3_bucket_name = "petpal-dev"
  config.s3_bucket_region = "us-west-1"
  config.s3_aws_access_key_id = "AKIAIZQ6XL7HT2B2VMMQ"
  config.s3_aws_secret_access_key = "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"

  # TTL for pet ownership invitations (1 week)
  config.pet_invitation_ttl_seconds = 7*24*60*60

  # Base URL for downstream auth service
  config.authsvc_base_url = "https://authpetpalci.herokuapp.com"

  #
  # A set of emails that are known to be internal users and
  # should be given more authorization
  #
  config.authorized_internal_users = ["herrstrudel@gmail.com"]

  # Redis
  config.redis_host = "localhost"
  config.redis_port = "6379"

  #
  # Setting this to true means:
  #
  #   1) redis.conf has a password specified, e.g.
  #
  #         masterauth supersecretpassword123
  #
  #   2) The slaves are required to provide a password
  #      when connecting to the master, e.g. in redis.conf:
  #
  #         requirepass supersecretpassword123
  #
  config.redis_password_required = true
  config.redis_password = "test123"

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static asset server for tests with Cache-Control for performance.
  config.serve_static_assets  = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.logger = ActiveSupport::TaggedLogging.new(Logger.new('log/petsvc-test.log', 'daily'))
  config.log_level = :info

end
