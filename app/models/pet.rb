
=begin

##############################
# NOTES: ON PETS
##############################

Pet:
=====
id
name
birth_year
creature_type
breed
weight
image
device_serial
creator
owner_user_ids
owner_invitation_tokens

RULES:
- API for pet can be accessed by both creator and users in the owner_user_ids list
- The operation to register a device for a pet can be done by either the creator or an owner
- A pet can have only 1 device registered
- To register another device for a pet, the old one has to be unregistered first
- The creator or the owner can invite additional owners for the pet
- Only the pet creator can remove the pet
- The users that are in the owners list can remove themselves as owner for the pet,
  but the pet is then still available for the creator and the other users
- The max number of owners for a pet is 100 users

=end

class Pet

  include Mongoid::Document

  # ID
  field :id, type: String, default: -> { SecureRandom.uuid }
  field :_id, type: String, default: ->{ id }
  index({ id: 1 }, { unique: true, background: true })

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
    greater_than_or_equal_to: 0, less_than: 100, only_integer: true, message: I18n.t("number_must_be_in_range", :range => "[0,99]")
  }

  #
  # TODO: Need to add a resource bundle for pet breeds and add a way to validate that the
  # pet breed given here is a valid breed for the type of pet given...
  #

  # CREATURE TYPE
  field :creature_type, type: Integer
  validates_presence_of :creature_type, message: I18n.t("field_is_required")
  validates :creature_type, numericality: {
      greater_than_or_equal_to: 0, less_than: 2, only_integer: true, message: I18n.t("number_must_be_in_range", :range => "[0,1]")
  }

  # TODO: Still need to add more fields here

end