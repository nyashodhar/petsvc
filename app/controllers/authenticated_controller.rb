class AuthenticatedController < ActionController::Base

  include AuthenticationHelper

  private

  #
  # Note: This method is used to pass the user information for an
  # authenticated user from the authentication filter to the
  # controller's action. This allows access to the user info from within
  # the action in the controller once the filter processing is done.
  #
  def set_authorization_info(authenticated_user_id, authenticated_email, internal_user)
    @authenticated_user_id = authenticated_user_id
    @authenticated_email = authenticated_email
    @internal_user = internal_user
  end

end