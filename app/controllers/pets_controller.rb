class PetsController < ActionController::Base

  include MongoIdHelper

  #######################################################
  # EXAMPLE LOCAL:
  # curl -v -X POST http://127.0.0.1:3000/pet -H "Accept: application/json" -H "Content-Type: application/json" -d '{"name":"Fido","birth_year":2012,"creature_type":0,"breed_bundle_id":"dog1","weight_grams":5100}'
  #######################################################
  def create_pet

    pet_args = request.params[:pet]

    # TODO: If a pet ownership does not exist, it needs to be created.
    # TODO: If a pet ownership exists

    # TODO: If this user owns too many pets, give a "412 Precondition Failed"

    #
    # TODO: Validate the prefix of the breed bundle id with the type of pet.
    # For example, if the pet is dog, the breed bundle id should start with 'dog'
    #

    pet = Pet.create(
        id: SecureRandom.uuid,
        name: pet_args[:name],
        birth_year: pet_args[:birth_year],
        creature_type: pet_args[:creature_type],
        breed_bundle_id: pet_args[:breed_bundle_id],
        weight_grams: pet_args[:weight_grams]
    )

    #
    # If the object fails validation, give a 422 error
    # If anything else fails, give 500 error
    #

    if(!pet.valid?)
      handle_mongoid_validation_error(pet, pet_args)
      return
    end

    begin
      pet.save!
    rescue => e
      logger.error "Unexpected error when saving pet from args #{pet_args}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
    end

    # Success 201
    render :status => 201, :json => {:id => pet.id, :name => pet.name, :creature_type => pet.creature_type, :breed_bundle_id => pet.breed_bundle_id, :weight_grams => pet.weight_grams}
  end

end