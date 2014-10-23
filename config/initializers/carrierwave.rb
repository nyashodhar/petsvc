
#
# Adds the ability to resize and specify quality in a single operation from uploader
#
# This becomes possible in an uploader:
#
#  process :resize_to_limit_with_quality => [Rails.application.config.s3_full_image_max_width, Rails.application.config.s3_full_image_max_height, 80]
#

module CarrierWave

  module MiniMagick

    def resize_to_limit_with_quality(width, height, percentage_quality)
      manipulate! do |img|
        img.resize "#{width}x#{height}>"
        img.quality(percentage_quality)
        img = yield(img) if block_given?
        img
      end
    end

  end
end