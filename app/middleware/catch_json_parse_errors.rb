####################################################
#
# This class ensures that all JSON parse errors
# result in 400 JSON responses
#
####################################################
class CatchJsonParseErrors
  def initialize(app)
    @app = app
    @logger = Rails.application.config.logger
  end

  def call(env)
    begin
      @app.call(env)
    rescue ActionDispatch::ParamsParser::ParseError => error

      @logger.error "CatchJsonParseErrors: A JSON parse error occurred: #{error}"
      error_output = I18n.t("400response_middleware_invalid_json")

      return [
          400, { "Content-Type" => "application/json" },
          [ { error: error_output }.to_json ]
      ]
    end
  end
end