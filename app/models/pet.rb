
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
- When an owner removes the pet from their mobile device, the pet will still linger for the other owners unless the
  owner that removes the pet is the last owner. This allows the data about the pet to be available to users of the
  service as long as anyone of the users is interested in tracking the pet.
- When a pet is remove such that it no longer has any owners, the registered device should be updated as no longer
  registered, allowing the device holder to register it to another pet at that point if the user wants.
- The max number of owners for a pet is 10 users
- The max number of pets that can be owned by a single user is 1000.

=end

class Pet

  include Mongoid::Document

  # ID
  field :pet_id, type: String, default: -> { SecureRandom.uuid }
  validates_presence_of :pet_id, message: I18n.t("field_is_required")
  index({ pet_id: 1 }, { unique: true, background: true })

  field :_id, type: String, default: ->{ pet_id }

  # NAME
  field :name, type: String
  validates_presence_of :name, message: I18n.t("field_is_required")
  validates :name, length: {
      minimum: 1, too_short: I18n.t("input_is_too_short"),
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

  # BIRTH YEAR
  field :birth_year, type: Integer
  validates_presence_of :birth_year, message: I18n.t("field_is_required")
  validates :birth_year, numericality: {
    greater_than_or_equal_to: 1970, less_than: 10000, only_integer: true, message: I18n.t("number_must_be_in_range", :range => "[1970,9999]")
  }

  # CREATURE TYPE
  field :creature_type, type: Integer
  validates_presence_of :creature_type, message: I18n.t("field_is_required")
  validates :creature_type, numericality: {
      greater_than_or_equal_to: 0, less_than: 2, only_integer: true, message: I18n.t("number_must_be_in_range", :range => "[0,1]")
  }

  # BREED_RESOURCE_BUNDLE_KEY
  field :breed_bundle_id, type: String
  validates_presence_of :breed_bundle_id, message: I18n.t("field_is_required")
  validates :breed_bundle_id, length: {
      minimum: 4, too_short: I18n.t("input_is_too_short"),
      maximum: 9, too_long: I18n.t("input_is_too_long")
  }

  # WEIGHT
  field :weight_grams, type: Integer
  validates_presence_of :weight_grams, message: I18n.t("field_is_required")
  validates :weight_grams, numericality: {
      greater_than_or_equal_to: 0, less_than: 300000, only_integer: true, message: I18n.t("number_must_be_in_range", :range => "[0,299000]")
  }

  # TODO: image_url

  #
  # DEVICE SERIAL
  # TODO: Figure out how to add a foreign key to the device object here, if that makes sense
  # If that does not make sense, we should probably at least have a unique index for
  # device serial in the pets to ensure that no two pets have the same device serial
  #
  field :device_serial, type: String, default: ->{ nil }
  #
  # validates :device_serial, length: {
  #    minimum: 0, too_short: I18n.t("input_is_too_short"),
  #    maximum: 256, too_long: I18n.t("input_is_too_long")
  #}

  #
  # TODO: CREATOR USER ID (meta data only)
  #

  # TODO: Still need to add more fields here

end