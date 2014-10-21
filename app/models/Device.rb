
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
  # DEVICE ID
  #
  field :device_id, type: String
  validates_presence_of :device_id, message: I18n.t("field_is_required")
  validates :device_id, length: {
      minimum: 8, too_short: I18n.t("input_is_too_short"),
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

  #
  # Override the _id field and replace it with the unique device_id
  #
  field :_id, type: String, default: ->{ device_id }

  #
  # DEVICE TYPE
  #
  field :device_type, type: String
  validates_presence_of :device_type, message: I18n.t("field_is_required")
  validates :device_type, length: {
      minimum: 1, too_short: I18n.t("input_is_too_short"),
      maximum: 56, too_long: I18n.t("input_is_too_long")
  }

  #
  # VERSION
  #
  field :device_version, type: String
  validates_presence_of :device_version, message: I18n.t("field_is_required")
  validates :device_version, length: {
      minimum: 1, too_short: I18n.t("input_is_too_short"),
      maximum: 28, too_long: I18n.t("input_is_too_long")
  }

  #
  # CREATION TIME (meta data)
  #
  field :creation_time, type: Time
  validates_presence_of :creation_time, message: I18n.t("field_is_required")

  #
  # CREATOR USER ID (meta data)
  #
  field :creator_user_id, type: Integer
  validates_presence_of :creator_user_id, message: I18n.t("field_is_required")


  #
  # REGISTRATION_USER_ID
  #
  field :user_id, type: Integer

  #
  # REGISTRATION_PET_ID
  #
  field :pet_id, type: String
  validates :pet_id, length: {
      maximum: 256, too_long: I18n.t("input_is_too_long")
  }

  #
  # REGISTRATION TIME (meta data)
  #
  field :registration_time, type: Time

  #
  # INDEXES
  #
  # Note on sparse indexes in mongo:
  #   http://stackoverflow.com/questions/8608567/sparse-indexes-and-null-values-in-mongo
  #
  index({ device_id: 1 }, { unique: true, background: true })
  index({ pet_id: 1 }, { unique: true, background: true, sparse: true })
  index({ user_id: 1 }, { unique: false, background: true, sparse: true })

end
