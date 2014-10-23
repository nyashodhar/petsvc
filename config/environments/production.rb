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

  # TTL for pet ownership invitations (1 week)
  config.pet_invitation_ttl_seconds = 7*24*60*60

  # Base URL for downstream auth service
  config.authsvc_base_url = "https://authsvc.petpal.mobi"

  #
  # A set of emails that are known to be internal users and
  # should be given more authorization
  #
  config.authorized_internal_users = ["herrstrudel@gmail.com"]

  # Redis
  # TODO: THE REDIS CONFIG NEEDS TO BE UPDATED LATER FOR THIS ENVIRONMENT
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

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable Rails's static asset server (Apache or nginx will already do this).
  config.serve_static_assets = false

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  # `config.assets.precompile` has moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Set to :debug to see everything in the log.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  # config.assets.precompile += %w( search.js )

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::DEBUG

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

end
