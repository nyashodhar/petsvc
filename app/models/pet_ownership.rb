class PetOwnership

  #
  # USER ID
  #
  field :user_id, type: Integer
  validates_presence_of :user_id, message: I18n.t("field_is_required")
  index({ user_id: 1 }, { unique: true, background: true })

  field :_id, type: String, default: ->{ user_id }

  # TODO: Create 1:N relationship from this object to the pet object.

end