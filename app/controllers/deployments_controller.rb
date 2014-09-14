##########################################################
#
# This controller was added to give a success response
# to the requests issued to the application after the
# completion of a CI build.
#
##########################################################
class DeploymentsController < ActionController::Base

  #######################################################
  # This handler should be targeted at the completion of
  # a CI build. If we want to convey some status, this
  # action is a good fit for that.
  #
  # EXAMPLE LOCAL:
  #   curl -v -X GET http://127.0.0.1:3000
  #######################################################
  def status
    # For now, just give a success response with no content
    head :no_content
  end
end