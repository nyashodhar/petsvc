####################################################
#
# This class ensures that some unexpected errors
# are responded to with 500 JSON response and not
# degenerate into HTML response.
#
####################################################
class CatchUnexpectedErrors
  def initialize(app)
    @app = app
    @logger = Rails.application.config.logger
  end

  def call(env)
    begin
      @app.call(env)
    rescue SyntaxError => error
      return handleError(error)
    rescue NameError => error
      return handleError(error)
    rescue RuntimeError => error
      return handleError(error)
    end
  end

  private

  def handleError(error)
    trace = error.backtrace[0,10].join("\n")
    @logger.error "CatchUnexpectedErrors: Error: #{error.class.name} : #{error.message}. Trace:\n#{trace}"
    error_output = I18n.t("500response_internal_server_error")

    return [
        500, { "Content-Type" => "application/json" },
        [ { error: error_output }.to_json ]
    ]
  end
end