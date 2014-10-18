module LocaleHelper

  #####################################################
  # Obtain a custom locale from the request and configure the
  # i18n to use that locale in all resource bundle lookups
  # made during the processing of this request.
  #####################################################
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

end