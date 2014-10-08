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
      logger.error "ensure_authorized(): The authenticated user #{@authenticated_email}:#{@authenticated_id} is not an internal user."
      render :status => 401, :json => {:error => I18n.t("401response")}
      return
    end

    logger.info "ensure_authorized(): The authenticated user #{@authenticated_email} is an internal user"
  end

  def ensure_owner_of_pet
    # TODO
  end
end