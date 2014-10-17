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

  #
  # This method is called by a filter that resolves authorization input parameters
  # from the request.
  #
  def set_pet_id_to_authorize(pet_id)
    @pet_id_to_authorize = pet_id
  end

  #
  # This method is called by a filter that resolves authorization input parameters
  # from the request.
  #
  def set_device_resolved_from_request(device)
    @device_resolved_from_request = device
  end

  #
  # This method is used by filters to obtain the pet id for which an authorization
  # operation can be performed. At this point we either have a pet_id obtained
  # from the request by another filter and stored in an instance variable, or
  # we will attempt to find a request parameter called 'pet_id'
  #
  def get_pet_id_for_authorization
    if(!@pet_id_to_authorize.blank?)
      return @pet_id_to_authorize
    end
    if(!params[:pet_id].blank?)
      return params[:pet_id]
    end
    logger.error "get_pet_id_for_authorization(): Unable to find pet_id for authorization, no pre-resolved id available and no id specified as pet_id in request, logged in user (#{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
    return nil
  end

end