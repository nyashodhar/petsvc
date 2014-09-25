class AuthenticatedController < ActionController::Base

  include AuthenticationHelper

  #
  # Note: This filter will do a downstream request to the auth service to
  # check that there is a sign-in for the auth token, and that the sign-in
  # is not expired
  #
  before_action :ensure_authorized

  private

  #
  # Note: This method is used to pass the user information for an
  # authenticated user from the authentication filter to the
  # controller's action. This allows access to the user info from within
  # the action in the controller once the filter processing is done.
  #
  def set_authenticated_user_id(authenticated_user_id, authenticated_email, internal_user)
    @authenticated_user_id = authenticated_user_id
    @authenticated_email = authenticated_email
    @internal_user = internal_user
  end

  def is_internal_user_authenticated
    return @internal_user
  end

end