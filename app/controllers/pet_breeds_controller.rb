#######################################################
# This controller provides an API to look up localized breed names for
# individual breeds for a given creature type.
#
# The client can select the locale for which to obtain the breed name
# by adding '?locale=ja' or '?locale=en' as a request parameter.
#######################################################
class PetBreedsController < ActionController::Base

  #
  # This filter allows the client to request breed-names from a different locale
  # by adding '?locale=ja' or '?locale=en' as a request parameter.
  #
  include LocaleHelper

  #######################################################
  # Obtain the localized breed name for the given
  # creature type and breed bundle id for the given locale
  #
  # 404:
  # - Breed bundle id was not found in the resource bundle
  #   for the given creature type
  #
  # 422:
  # - Creature type is invalid
  #
  # EXAMPLE LOCAL:
  # curl -v -X GET http://127.0.0.1:3000/creature/:creature_type/breed/:breed_bundle_id -H "Accept: application/json" -H "Content-Type: application/json"
  #######################################################
  def get_breed_for_breed_bundle_id
    # TODO
    head 204
  end

  #######################################################
  # Obtain the breed bundle ids and the localized breed name
  # for each breed bundle id.
  #
  # 404:
  # - Not a single localized breed bundle id was found for the
  #   specified creature type for request's locale.
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