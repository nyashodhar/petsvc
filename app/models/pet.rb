
=begin

##############################
# NOTES: ON PETS AND DEVICES
##############################

Pet:
=====

RULES:
- A Pet can be owned by multiple users
- After the pet has been created by a user, the user can invite another user to become an owner
- The pet API for the pet can be accessed by all owners of the pet
- A pet can have only 1 device registered
- To register another device for a pet, the old one has to be unregistered first
- When an owner removes the pet from their mobile device, the pet will still linger for the other owners.
- It's not allowed for a user to remove his/her ownership for a pet as long as the user has a device registered for the pet
- The max number of owners for a pet is 10 users (TODO)
- The max number of pets that can be owned by a single user is 1000 (TODO)

=end

class Pet

  include Mongoid::Document

  #
  # ID
  #
  field :pet_id, type: String, default: -> { SecureRandom.uuid }
  validates_presence_of :pet_id, message: I18n.t("field_is_required")

  field :_id, type: String, default: ->{ pet_id }

  #
  # NAME
  #
  field :name, type: String
  validates_presence_of :name, message: I18n.t("field_is_required")
  validates :name, length: {
      minimum: 1, too_short: I18n.t("input_is_too_short"),
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

  #
  # BIRTH YEAR
  #
  field :birth_year, type: Integer
  validates_presence_of :birth_year, message: I18n.t("field_is_required")
  validates :birth_year, numericality: {
    greater_than_or_equal_to: 1970, less_than: 10000, only_integer: true, message: I18n.t("number_must_be_in_range", :range => "[1970,9999]")
  }

  #
  # CREATURE TYPE
  #
  field :creature_type, type: Integer
  validates_presence_of :creature_type, message: I18n.t("field_is_required")
  validates :creature_type, numericality: {
      greater_than_or_equal_to: 0, less_than: 2, only_integer: true, message: I18n.t("number_must_be_in_range", :range => "[0,1]")
  }

  #
  # BREED_RESOURCE_BUNDLE_KEY
  #
  field :breed_bundle_id, type: String
  validates_presence_of :breed_bundle_id, message: I18n.t("field_is_required")
  validates :breed_bundle_id, length: {
      minimum: 4, too_short: I18n.t("input_is_too_short"),
      maximum: 9, too_long: I18n.t("input_is_too_long")
  }

  #
  # WEIGHT
  #
  field :weight_grams, type: Integer
  validates_presence_of :weight_grams, message: I18n.t("field_is_required")
  validates :weight_grams, numericality: {
      greater_than_or_equal_to: 0, less_than: 300000, only_integer: true, message: I18n.t("number_must_be_in_range", :range => "[0,299000]")
  }

  #
  # AVATAR UPLOAD ID (full sized version of the avatar image)
  #
  field :avatar_upload_id, type: String
  validates :avatar_upload_id, length: {
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

  #
  # AVATAR UPLOAD ID THUMB (smaller sized version of the avatar image)
  #
  field :avatar_upload_id_thumb, type: String
  validates :avatar_upload_id_thumb, length: {
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

  #
  # CREATOR USER ID (meta data)
  #
  field :creator_user_id, type: Integer
  validates_presence_of :creator_user_id, message: I18n.t("field_is_required")

  #
  # INDEXES
  #
  index({ pet_id: 1 }, { unique: true, background: true })

end