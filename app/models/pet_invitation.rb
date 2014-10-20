#################################################
#
# A couple of things to note about pet invitations:
#
# The invitation_id is unique among all invitations
# not yet responded to and not yet expired.
#
# It's allowed to have multiple invitations non-expired and
# non-responded invitations for the same pet_id, as long
# as all those invitations have different invitation_ids.
#
#################################################

class PetInvitation

  include Mongoid::Document

  #
  # INVITATION ID
  #
  field :invitation_id, type: String
  validates_presence_of :invitation_id, message: I18n.t("field_is_required")
  validates :invitation_id, length: {
      minimum: 11, too_short: I18n.t("input_is_too_short"),
      maximum: 11, too_long: I18n.t("input_is_too_long")
  }

  #
  # PET ID
  #
  field :pet_id, type: String
  validates_presence_of :pet_id, message: I18n.t("field_is_required")

  #
  # INVITATION EXPIRATION TIME
  #
  field :expiration_time, type: Time
  validates_presence_of :expiration_time, message: I18n.t("field_is_required")

  #
  # CREATOR USER ID (the user that created the invitation - meta data)
  #
  field :creator_user_id, type: Integer
  validates_presence_of :creator_user_id, message: I18n.t("field_is_required")

  #
  # USER ID OF USER THAT RESPONDED TO THE INVITATION
  #
  field :responder_user_id, type: Integer

  #
  # INDEXES
  #
  index({ invitation_id: 1, expiration_time: 1, responder_user_id: 1}, { unique: false, background: true })

end