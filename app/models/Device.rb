
####################################################
#
# RANDOM NOTES:
# ===============================
#
# Indexing in mongoid:
#
#   http://mongoid.org/en/mongoid/docs/indexing.html
#
# To create the index:
#
#   rake db:mongoid:create_indexes RAILS_ENV=test
#   rake db:mongoid:create_indexes RAILS_ENV=development
#
# This page describes how to override the _id field in an object:
#
#   http://mongoid.org/en/mongoid/v3/documents.html
#
# In mongo shell:
# ---------------------
#
# Switch to a db:
#   use petsvc_development
#
# Show the collections in the current db:
#   show collections
#
# List all the objects in a collection in the current db:
#   db.devices.find()
#
# Drop db:
#   db.dropDatabase();
#
# List all the objects in a collection in the current db:
#   db.devices.find()
#
# Find the pet ownerships for a given user id
#   db.device_registrations.find( { user_id: 12 } )

####################################################

class Device

  include Mongoid::Document

  #
  # Serial number field
  #
  field :serial, type: String
  index({ serial: 1 }, { unique: true, background: true })
  validates_presence_of :serial, message: I18n.t("field_is_required")
  validates :serial, length: {
      minimum: 8, too_short: I18n.t("input_is_too_short"),
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

  #
  # Override the _id field and replace it with the unique serial number values
  #
  field :_id, type: String, default: ->{ serial }

  #
  # TODO: Add device version field
  #

  #
  # REGISTRATION_USER_ID
  #
  field :user_id, type: Integer

  #
  # REGISTRATION_PET_ID
  #
  # Note on sparse indexes in mongo:
  #   http://stackoverflow.com/questions/8608567/sparse-indexes-and-null-values-in-mongo
  #
  # How to remove a field from a doc:
  #   https://coderwall.com/p/wcx4pq
  #

  field :pet_id, type: String
  index({ pet_id: 1 }, { unique: true, background: true, sparse: true })
  validates :pet_id, length: {
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

end
