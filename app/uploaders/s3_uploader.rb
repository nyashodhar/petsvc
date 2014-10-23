##########################################################################
# Notes:
#
# FOG CREDENTIALS:
# ==================================
#
# I have set up this user in the AWS IAM and added aws keys
#      User: petpal-dev-user
#      Access Key ID: AKIAIZQ6XL7HT2B2VMMQ
#      Secret Access Key: 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
#
# Doc on how to create aws_access_key_id and aws_secret_access_key
#
#   http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSGettingStartedGuide/AWSCredentials.html
#
# The 'region' can optionally be set to the region of the bucket. Setting region to another value
# than the region set for the bucket in AWS gives a redirect response on upload:
#
#   301 Moved Permanently: "The bucket you are attempting to access must be addressed using the specified endpoint. Please send all future requests to this endpoint.&lt;/Message&gt;&lt;RequestId&gt;5BCB0AFCD3BD1F63&lt;/RequestId&gt;&lt;Bucket&gt;petpal-dev&lt;/Bucket&gt;&lt;HostId&gt;QE6J+EIlLdTafeYCt4BK70BCcukKd5Nw2XOkRvh/d7RGkQ1593oix9kK1ivKz7vdmo2vYm/o+VM=&lt;/HostId&gt;&lt;Endpoint&gt;petpal-dev.s3-us-west-1.amazonaws.com&lt;/Endpoint&gt;&lt;/Error&gt;&quot;"
#
# The same type of redirect is given if attempting to do a get request for a file after it has been uploaded.
#
# Valid values for region are:
#
#   'eu-west-1', 'us-east-1', 'ap-southeast-1', 'us-west-1', 'ap-northeast-1'
#
# OTHER SETTINGS:
#
# config.fog_directory:
#   -  Is the name of the S3 bucket e.g. petpal-dev
#
# config.fog_public:
#
#   - Setting to 'true' makes all the files upload public, this make all the urls deterministic and accessible.
#   - Combining this with UUID-based filenames should be secure enough for all petpal users
#   - To make fog_public work in AWS the following steps are needed in AWS
#      1) Select the user to which the AWS access key belongs in the AWS IAM console
#      2) Select 'Attach User Policy'
#      3) In the list of policy templates, select 'Amazon S3 Full Access'
#      4) In the S3 bucket itself, go to properties, then permissions and add grantee 'Authenticated Users' and check all checkboxes.
#
# config.fog_attributes:
#    - Cache-Control header will govern how long browsers will be allowed to cache the file
#
##########################################################################
class S3Uploader < CarrierWave::Uploader::Base

  # This is required for resizing
  include CarrierWave::MiniMagick

  ############################################
  # This uploader will upload an image to S3.
  #
  # Note: Image scaling and thumb versions
  # ==============================================
  #
  # If instructed to do so, the uploader will upload a 2nd
  # thumbnail version of the image. In addition to the full
  # size image.
  #
  # Both the thumbnail and the full size image is scaled to fit
  # within certain bounds. The image is never scaled up to fit
  # those bounds, only downscaling will be performed.
  #
  # The aspect ratio of the image will not be altered by any
  # of the scaling operations.
  #
  # Note: HOWTO introduce multiple S3 buckets.
  # ==============================================
  #
  # Specify our S3 bucket config here rather than use an initializer
  #
  # This will allow for easy introduction of multiple buckets in the
  # application later since the initializer config only allows for
  # specification of a single bucket.
  #
  # A bucket is tied to a region/locale. For example, if it's desired
  # to funnel uploads from requests to a bucket in a specific region
  # based on the locale or other information int the request, that can
  # easily be achieved by adding another parameter to this initializer
  # and allow this initializer to make an intelligent bucket choice.
  ############################################
  def initialize(uploads_dir, file_name)

    super

    @logger = Rails.application.config.logger

    @uploads_dir = uploads_dir
    @file_name = file_name
    #@create_thumb = create_thumb

    @thumb_max_width = Rails.application.config.s3_thumb_image_max_width
    @thumb_max_height = Rails.application.config.s3_thumb_image_max_height

    self.fog_credentials = {
        :provider               => 'AWS',
        :aws_access_key_id      => Rails.application.config.s3_aws_access_key_id,
        :aws_secret_access_key  => Rails.application.config.s3_aws_secret_access_key,
        :region                 => Rails.application.config.s3_bucket_region
    }
    self.fog_directory = Rails.application.config.s3_bucket_name
    self.fog_public = true
    self.fog_attributes = {'Cache-Control'=>"max-age=#{365.day.to_i}"}
  end

  storage :fog

  include CarrierWave::MimeTypes

  process :set_content_type

  def get_bucket_region
    return self.fog_credentials[:region]
  end

  def store_dir
    @uploads_dir
  end

  def filename
    @file_name
  end

  def set_create_thumb(create_thumb)
    @create_thumb = create_thumb
  end

  #
  # Ensure the full-size version of the image is not beyond a certain box
  #

  process :store_dimensions
  process :convert => 'jpg'
  process :resize_to_limit_with_quality => [Rails.application.config.s3_full_image_max_width, Rails.application.config.s3_full_image_max_height, 80]

  #
  # Make a thumb version of the image
  #

  version :thumb, :if => :make_thumbnail? do
    if(@image_width.blank? && @image_width.blank?)
      process :store_dimensions
    end
    process :convert => 'jpg'
    process :resize_to_limit_with_quality => [Rails.application.config.s3_thumb_image_max_width, Rails.application.config.s3_thumb_image_max_height, 80]
  end

  private

  def make_thumbnail?(img)

    #
    # Note: this callback ends up being called multiple times by carrier wave.
    # Use a boolean flag to avoid multiple entries for the same info in the log
    #

    if(@make_thumnail_already_called)
      return @create_thumb
    end

    @logger.debug "make_thumbnail?(): img = #{img.inspect}"
    if(@create_thumb)
      @logger.info "make_thumbnail?(): A thumb version will be created to fit the box [#{@thumb_max_width}, #{@thumb_max_height}], the uploaded image has #{@image_width} pixels width and #{@image_height} height."
      @make_thumnail_already_called = true
      return true
    else
      @logger.info "make_thumbnail?(): No thumb version of the image will be created, the uploaded image has #{@image_width} pixels width and #{@image_height} height."
      @make_thumnail_already_called = true
      return false
    end
  end

  def store_dimensions
    if file && model
      @image_width, @image_height = ::MiniMagick::Image.open(file.file)[:dimensions]
      @logger.debug "store_dimensions(): @image_width = #{@image_width}, @image_height = #{@image_height}\n"
    end
  end

  #def cache_dir
  #  "/tmp/uploads"
  #end

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  #storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  #def store_dir
  #  "uploads/testuploaddir"
  #  #STDOUT.write "*** DO WE GET HERE???"
  #  #"uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  #end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :resize_to_fit => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end