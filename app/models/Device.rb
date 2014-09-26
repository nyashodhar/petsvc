
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
#   rake db:mongoid:create_indexes
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

end
