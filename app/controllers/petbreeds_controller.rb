#######################################################
# This controller provides an API to look up localized breed names for
# pet breeds for a given creature type.
#
# The client can select the locale for which to obtain the breed names
# by adding '?locale=ja' or '?locale=en' as a request parameter.
#######################################################
class PetbreedsController < ActionController::Base

  #
  # This filter allows the client to request breed-names from a different locale
  # by adding '?locale=ja' or '?locale=en' as a request parameter.
  #
  include LocaleHelper
  before_action :set_locale

  #######################################################
  # Obtain the localized breed name for the breed_bundle_id given
  # for the given locale
  #
  # 404:
  # - A localized breed name was not found for the breed bundle id
  #  in the resource bundle for the specified locale.
  #
  # 422:
  # - Breed bundle id is missing
  #
  # EXAMPLE LOCAL:
  # curl -v -X GET http://127.0.0.1:3000/breed/dog2 -H "Accept: application/json" -H "Content-Type: application/json"
  # curl -v -X GET http://127.0.0.1:3000/breed/dog2?locale=ja -H "Accept: application/json" -H "Content-Type: application/json"
  #######################################################
  def get_breed_for_breed_bundle_id

    breed_bundle_id = params[:breed_bundle_id]

    if(breed_bundle_id.blank?)
      #
      # This is probably never gonna happen since without the breed_bundle_id being present
      # the request would not get routed to this action...
      #
      logger.error "get_breed_for_breed_bundle_id(): breed_bundle_id is missing"
      errors_hash = {:breed_bundle_id => [I18n.t("field_is_required")]}
      render :status => 422, :json => {:error => errors_hash}
      return false
    end

    # Note: provide default here to avoid to stuff like "translation missing: en.dog7"
    localized_breed_name = I18n.t(breed_bundle_id.to_s, :default => "")

    if(localized_breed_name.blank?)
      logger.error "get_breed_for_breed_bundle_id(): No localized breed name found for breed_bundle_id #{breed_bundle_id} for locale #{I18n.locale}"
      render :status => 404, :json => {:error => I18n.t("404response_resource_not_found")}
      return false
    end

    render :status => 200, :json => {:breed => localized_breed_name, :locale => I18n.locale}
  end

  #######################################################
  # Obtain the breed bundle ids and the localized breed name
  # for each breed bundle id.
  #
  # 404:
  # - Not a single localized breed name was found for any breed bundle id for the
  #  specified creature type for the given locale.
  #
  # 422:
  # - Creature type is invalid
  #
  # EXAMPLE LOCAL:
  # curl -v -X GET http://127.0.0.1:3000/creature/:creature_type -H "Accept: application/json" -H "Content-Type: application/json"
  #######################################################
  def get_all_breeds_for_creature_type
    # TODO
    head 204
  end

end