Rails.application.configure do

  # Settings specified here will take precedence over those in config/application.rb.

  # Config used for amazon s3 file uploads
  config.s3_bucket_name = "petpal-dev"
  config.s3_bucket_region = "us-west-1"
  config.s3_aws_access_key_id = "AKIAIZQ6XL7HT2B2VMMQ"
  config.s3_aws_secret_access_key = "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"
  config.s3_full_image_max_width = 1280
  config.s3_full_image_max_height = 1280
  config.s3_thumb_image_max_width = 300
  config.s3_thumb_image_max_height = 300
  config.s3_incoming_request_max_bytes = (5*1024*1024).to_i
  
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
  #         masterauth test123
  #
  #   2) The slaves are required to provide a password
  #      when connecting to the master, e.g. in redis.conf:
  #
  #         requirepass test123
  #
  config.redis_password_required = true
  config.redis_password = "test123"

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  #Logger Config
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new('log/petsvc-dev.log', 'daily'))
  config.log_level = :info

end
