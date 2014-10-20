class PetInvitation

  include Mongoid::Document

  #
  # INVITATION ID
  #
  field :invitation_id, type: String
  validates_presence_of :invitation_id, message: I18n.t("field_is_required")

  #
  # PET ID
  #
  field :pet_id, type: String
  validates_presence_of :pet_id, message: I18n.t("field_is_required")

  #
  # INVITATION EXPIRATION TIME
  #
  field :expiration_time, type: DateTime
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

end