
#
# Switch to a db:
#   use petsvc_development
#
# Show the collections in the current db:
#   show collections
#
# List all the objects in a collection in the current db:
#   db.pet_ownerships.find()
#

class PetOwnership

  #
  # USER ID
  #
  field :user_id, type: Integer
  validates_presence_of :user_id, message: I18n.t("field_is_required")
  #index({ user_id: 1 }, { unique: true, background: true })

  field :_id, type: String, default: ->{ user_id }

  #
  # PET ID
  #
  field :pet_id, type: String
  validates_presence_of :pet_id, message: I18n.t("field_is_required")

  #
  # (user_id, pet_id) should be a unique composite key
  #

  index({ user_id: 1, pet_id: 1 }, { unique: true, background: true })
end