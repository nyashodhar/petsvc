#######################################################
# This controller provides an API to look up localized breed names for
# pet breeds for a given creature type.
#
# The client can select the locale for which to obtain the breed names
# by adding '?locale=ja' or '?locale=en' as a request parameter.
#######################################################
class PetbreedsController < ActionController::Base

  include PetBreedHelper

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
  # 500:
  # - Creature name could not be resolved for a valid creature_type
  #
  # EXAMPLE LOCAL:
  # curl -v -X GET http://127.0.0.1:3000/breed/creature/0 -H "Accept: application/json" -H "Content-Type: application/json"
  # curl -v -X GET http://127.0.0.1:3000/breed/creature/1?locale=ja -H "Accept: application/json" -H "Content-Type: application/json"
  #######################################################
  def get_all_breeds_for_creature_type

    creature_type = params[:creature_type]

    if(!creature_type_valid?(creature_type))
      logger.error "get_all_breeds_for_creature_type(): creature_type #{creature_type} is invalid"
      errors_hash = {:creature_type => [I18n.t("number_must_be_in_range", :range => "[0,1]")]}
      render :status => 422, :json => {:error => errors_hash}
      return false
    end

    # Fetch a mapping (breed_bundle_id => localized_breed_name)
    localized_breed_names = get_all_breed_names(creature_type)

    if(localized_breed_names.blank? || localized_breed_names.length == 0)
      logger.error "get_all_breeds_for_creature_type(): No localized breed names found for creature type #{creature_type} for locale #{I18n.locale}"
      render :status => 404, :json => {:error => I18n.t("404response_resource_not_found")}
      return false
    end

    creature_name_bundle_id = get_breed_bundle_prefix_for_creature_type(creature_type)
    creature_name = I18n.t(creature_name_bundle_id, :default => "")
    if(creature_name.blank?)
      logger.error "get_all_breeds_for_creature_type(): Unable to find creature name for creature type #{creature_type}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    render :status => 200, :json => {:creature_type => creature_type, creature_name: creature_name, :locale => I18n.locale, :breeds => localized_breed_names}
  end

end