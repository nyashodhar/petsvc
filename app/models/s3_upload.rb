class S3Upload

  include Mongoid::Document

  ################################################################
  #
  # Scheme for storing files on S3:
  #
  # BUCKET/HEAP/SUBHEAP/FILENAME
  #
  ################################################################

  #
  # CREATION TIME (meta data)
  #
  field :expiration_time, type: Time
  validates_presence_of :expiration_time, message: I18n.t("field_is_required")

  #
  # UPLOADER USER ID (meta data)
  #
  field :uploader_user_id, type: Integer
  validates_presence_of :uploader_user_id, message: I18n.t("field_is_required")

  #
  # BUCKET NAME
  #
  field :bucket_name, type: String
  validates_presence_of :bucket_name, message: I18n.t("field_is_required")
  validates :bucket_name, length: {
      minimum: 1, too_short: I18n.t("input_is_too_short"),
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

  #
  # BUCKET REGION
  #
  field :bucket_region, type: String
  validates_presence_of :bucket_region, message: I18n.t("field_is_required")
  validates :bucket_region, length: {
      minimum: 1, too_short: I18n.t("input_is_too_short"),
      maximum: 28, too_long: I18n.t("input_is_too_long")
  }

  #
  # HEAP
  #
  field :heap, type: String
  validates_presence_of :heap, message: I18n.t("field_is_required")
  validates :heap, length: {
      minimum: 1, too_short: I18n.t("input_is_too_short"),
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

  #
  # SUBHEAP
  #
  field :subheap, type: String
  validates_presence_of :subheap, message: I18n.t("field_is_required")
  validates :subheap, length: {
      minimum: 1, too_short: I18n.t("input_is_too_short"),
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

  #
  # FILE NAME
  #
  field :file_name, type: String
  validates_presence_of :file_name, message: I18n.t("field_is_required")
  validates :file_name, length: {
      minimum: 1, too_short: I18n.t("input_is_too_short"),
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

  #
  # URL
  #
  field :url, type: String
  validates_presence_of :url, message: I18n.t("field_is_required")
  validates :url, length: {
      minimum: 1, too_short: I18n.t("input_is_too_short"),
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

  index({ invitation_id: 1, expiration_time: 1}, { unique: false, background: true })

end