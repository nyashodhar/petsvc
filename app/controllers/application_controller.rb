class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from StandardError do |e|
    error(e)
  end

  def error(e)
    trace = e.backtrace[0,10].join("\n")
    logger.error "Custom error handler - Error: #{e.class.name} : #{e.message}, Trace: #{trace}"
    render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
  end

  def not_found
    logger.error "Custom 404 Handler: No route found for path #{request.path}"
    render :status => 404, :json => {:error => I18n.t("404response_resource_not_found")}
  end
end
