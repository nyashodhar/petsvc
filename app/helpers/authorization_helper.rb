##########################################################
#
# The role of the methods in this module is to perform
# authorizations checks. Authorization checks happen
# after authentication checks.
#
##########################################################
module AuthorizationHelper

  ################################################
  #
  # Ensures that the authenticated user is contained
  # on the list of users designated as 'internal users'
  #
  # This filter assumes that the authentication filter (ensure_authenticated)
  # has already been successfully applied.
  #
  # Responses:
  #
  # 401:
  #  - If an authenticated user is not present
  #  - If the authenticated user is not an internal user
  #
  # If no 401 is given to the client, control passes
  # beyond this filter.
  #
  ################################################
  def ensure_internal_user

    if(@authenticated_email.blank?)
      logger.error "ensure_internal_user(): No authenticated email present, this should not happen, check order of filters in controller"
      render :status => 401, :json => {:error => I18n.t("401response")}
      return
    end

    authenticated_internal_user = Rails.application.config.authorized_internal_users.include?(@authenticated_email)

    if(!authenticated_internal_user)
      logger.error "ensure_internal_user(): The authenticated user #{@authenticated_email}:#{@authenticated_user_id} is not an internal user."
      render :status => 401, :json => {:error => I18n.t("401response")}
      return
    end

    logger.info "ensure_internal_user(): The authenticated user #{@authenticated_email}:#{@authenticated_user_id} is an internal user"
  end


  ################################################
  #
  # Ensures that the authenticated user has an ownership
  # record for a pet. The id of the pet can originate
  # from the request, or the pet id could have been
  # determined from another resource earlier by another filter.
  #
  # This filter assumes that the authentication filter (ensure_authenticated)
  # has already been successfully applied.
  #
  # Responses:
  #
  # 422:
  #  - If no pet_id was given
  #
  # 401:
  #  - If no ownership record was found for the given pet_id
  #  - An ownership record was found, but the pet itself no longer
  #    exists (which should never happen)
  #
  # If no 401 or 422 is given to the client, control passes
  # beyond this filter.
  #
  ################################################
  def ensure_owner_of_pet

    pet_id = get_pet_id_for_authorization

    if(pet_id.blank?)
      logger.error "ensure_owner_of_pet(): No pet_id available => unable to determine pet ownership"
      render :status => 422, :json => {:error => I18n.t("422response")}
      return
    end

    begin
      PetOwnership.find_by(user_id: @authenticated_user_id, pet_id: pet_id)
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error "ensure_owner_of_pet(): The authenticated user (#{@authenticated_email}:#{@authenticated_user_id}) is not an owner of a pet with id #{pet_id}"
      render :status => 401, :json => {:error => I18n.t("401response")}
      return
    end

    begin
      pet = Pet.find_by(pet_id: pet_id)
    rescue Mongoid::Errors::DocumentNotFound => e

      #
      # This should never happen. It would mean that the pet ownership is still present,
      # but the pet is not found. In this case, do special logging, but give 401 to the client
      #

      logger.error "ensure_owner_of_pet(): No pet with id #{pet_id} found, but ownership was found for user #{@authenticated_email}:#{@authenticated_user_id}, this should never happen!"
      render :status => 401, :json => {:error => I18n.t("401response")}
      return
    end

    set_owned_pet(pet)

    logger.info "ensure_owner_of_pet(): The authenticated user #{@authenticated_email}:#{@authenticated_user_id} is an owner of pet #{pet_id}"
  end


  ################################################
  #
  # This filter resolves a pet id from a device object so
  # that the pet id can be used for authorization purposes
  # by subsequent filters.
  #
  # 422:
  # - Device id is missing from request
  #
  # 401:
  # - No device found for device id
  # - The device is not registered, making pet-id authorization impossible
  #
  # 500:
  # - The device is registered but has no user id
  # - The device is registered but has no pet id
  #
  ################################################
  def resolve_pet_id_from_device_registration

    device_id = params[:device_id]

    if(device_id.blank?)
      logger.error "resolve_pet_id_from_device_registration(): No device_id provided, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      errors_hash = {:device_id => [I18n.t("field_is_required")]}
      render :status => 422, :json => {:error => errors_hash}
      return
    end

    begin
      device = Device.find_by(device_id: device_id)
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error "resolve_pet_id_from_device_registration(): No device found for device_id #{device_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 401, :json => {:error => I18n.t("401response")}
      return
    end

    if(device.pet_id.blank? && device.user_id.blank?)
      logger.error "resolve_pet_id_from_device_registration(): The device #{device_id} is not registered to any pet or user, resolution of pet id for authorization not possible, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 401, :json => {:error => I18n.t("401response")}
      return
    end

    if(device.user_id.blank?)
      logger.error "resolve_pet_id_from_device_registration(): The device #{device_id} appears to be registered, but has no user id. This should never happen, device = #{device.inspect}, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    if(device.pet_id.blank?)
      logger.error "resolve_pet_id_from_device_registration(): The device #{device_id} appears to be registered, but has no pet id. This should never happen, device = #{device.inspect}, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    set_pet_id_to_authorize(device.pet_id)
    set_device_resolved_from_request(device)

    logger.info "resolve_pet_id_from_device_registration(): resolved pet id #{device.pet_id} to authorize for user #{@authenticated_email}:#{@authenticated_user_id} from device #{device_id}"
  end

end