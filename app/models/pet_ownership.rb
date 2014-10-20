
#
# To create the indexes:
#
#   rake db:mongoid:create_indexes RAILS_ENV=test
#   rake db:mongoid:create_indexes RAILS_ENV=development
#
# In mongo shell:
# ====================
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
# Find the pet ownerships for a given user id
#   db.pet_ownerships.find( { user_id: 12 } )
#

class PetOwnership

  include Mongoid::Document

  #
  # USER ID
  #
  field :user_id, type: Integer
  validates_presence_of :user_id, message: I18n.t("field_is_required")

  #
  # PET ID
  #
  field :pet_id, type: String
  validates_presence_of :pet_id, message: I18n.t("field_is_required")

  #
  # INDEXES:
  # Note: (user_id, pet_id) should be a unique composite key
  #
  index({ user_id: 1, pet_id: 1 }, { unique: true, background: true })
  index({ user_id: 1 }, { unique: false, background: true })

end