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
  # record for the pet identified by the pet_id path variable.
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

    pet_id = params[:pet_id]

    if(pet_id.blank?)
      logger.error "ensure_owner_of_pet(): No pet_id path variable in the request => unable to determine pet ownership"
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
      pet = Pet.find_by(id: pet_id)
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

    logger.info "ensure_owner_of_pet(): The authenticated user #{@authenticated_email}:#{@authenticated_user_id} is the owner of pet #{pet_id}"
  end

end