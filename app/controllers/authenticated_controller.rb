class AuthenticatedController < ActionController::Base

  include AuthenticationHelper
  include AuthorizationHelper

  private

  #
  # Note: This method is used to pass the user information for an
  # authenticated user from the authentication filter to the
  # controller's action and/or other filters.
  #
  def set_authentication_info(authenticated_user_id, authenticated_email)
    @authenticated_user_id = authenticated_user_id
    @authenticated_email = authenticated_email
  end

  #
  # This method is called from the ensure_owner_of_pet authorization filter
  # when it has been established that the authenticated user is the owner
  # of this pet.
  #
  def set_owned_pet(pet)
    @owned_pet = pet
  end

end