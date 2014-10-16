class PetsController < AuthenticatedController

  include MongoIdHelper

  before_action :ensure_authenticated
  before_action :ensure_owner_of_pet, only: [:update_pet]

  #######################################################
  # Updates an existing pet object.
  #
  # 401:
  #  - Authenticated failed (user not logged in)
  #  - Authorization failed (the logged in user is not owner of the pet)
  # 422:
  #  - One or more of the fields in the pet object were invalid
  # 500:
  #  - An unexpected error occurred while updating the pet object
  #
  # EXAMPLE LOCAL:
  # curl -v -X PUT http://127.0.0.1:3000/pet/9d855750-db24-4f15-805b-aaf0309980b9 -H "Accept: application/json" -H "Content-Type: application/json" -H "X-User-Token: e4SnXXxoWd_Kxi67L-xf" -d '{"name":"Fido","birth_year":2012,"creature_type":0,"breed_bundle_id":"dog1","weight_grams":5100}'
  #######################################################
  def update_pet

    pet_args = request.params[:pet]

    #
    # Update the fields in the pet object
    # Note that it's allowed for the client to only update a subset of all
    # the fields of a pet in a single request
    #

    if(!pet_args[:name].blank?)
      @owned_pet.name = pet_args[:name]
    end

    if(!pet_args[:birth_year].blank?)
      @owned_pet.birth_year = pet_args[:birth_year]
    end

    if(!pet_args[:creature_type].blank?)

      #
      # TODO: Validate the prefix of the breed bundle id with the type of pet.
      # For example, if the pet is dog, the breed_bundle_id specified must exist
      # in the dog resource bundle.
      #

      #
      # If the creature type is specified, then we must also require that the
      # breed is specified. Otherwise, the creature type could be changed
      # from 'dog' to 'cat' while breed is still 'doberman' ...:-)
      #

      if(pet_args[:breed_bundle_id].blank?)
        logger.error "Creature type specified, but no breed_bundle_id specified. pet_id = #{@owned_pet.pet_id}, logged in user = #{@authenticated_email}:#{@authenticated_user_id}"
        errors_hash = {:breed_bundle_id => [I18n.t("field_is_required")]}
        #{"error":{"breed_bundle_id":["Field is required"]}}
        render :status => 422, :json => {:error => errors_hash}
      end

      @owned_pet.breed_bundle_id = pet_args[:breed_bundle_id]
      @owned_pet.creature_type = pet_args[:creature_type]
    end

    if(!pet_args[:weight_grams].blank?)
      @owned_pet.weight_grams = pet_args[:weight_grams]
    end

    begin
      @owned_pet.save!
      logger.info "Pet #{@owned_pet.pet_id} was successfully updated by user #{@authenticated_email}:#{@authenticated_user_id}"
    rescue => e
      logger.error "Unexpected error when updating pet #{@owned_pet.pet_id}. User #{@authenticated_email}:#{@authenticated_user_id}) - args #{pet_args} - error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    head 204
  end


  #######################################################
  # Creates a new pet object. When the pet object has
  # successfully created, a pet ownership object is created
  # to record that the authenticated user is an owner of the
  # pet that has been created.
  #
  # 401:
  #  - Authenticated failed
  # 412:
  #  - The user owns too many pets (TODO)
  # 422:
  #  - One or more of the fields in the pet object were invalid
  # 500:
  #  - An unexpected error occurred while creating the pet object
  #
  # EXAMPLE LOCAL:
  # curl -v -X POST http://127.0.0.1:3000/pet -H "Accept: application/json" -H "Content-Type: application/json" -H "X-User-Token: qjWSpXyqmvvQnqM8Ujpn" -d '{"name":"Fido","birth_year":2012,"creature_type":0,"breed_bundle_id":"dog1","weight_grams":5100}'
  #######################################################
  def create_pet

    pet_args = request.params[:pet]

    #
    # TODO: Validate the prefix of the breed bundle id with the type of pet.
    # For example, if the pet is dog, the breed_bundle_id specified must exist
    # in the dog resource bundle.
    #

    pet = Pet.create(
        pet_id: SecureRandom.uuid,
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
      return
    end

    #
    # The pet object was created, create a pet ownership
    #

    if(@authenticated_user_id.blank?)
      logger.error "No authenticated user id present => unable to create pet ownership"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    pet_ownership = PetOwnership.create(
        user_id: @authenticated_user_id,
        pet_id: pet.pet_id
    )

    if(!pet_ownership.valid?)
      handle_mongoid_validation_error(pet_ownership)
      return
    end

    #
    # TODO: Hmm, is the save needed looks like the doc was created without it?
    #

    begin
      pet_ownership.save!
    rescue => e
      logger.error "Unexpected error when saving pet ownership for pet (#{@authenticated_email}:#{@authenticated_user_id}), args #{pet_args}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    # Success 201
    render :status => 201, :json => {:id => pet.pet_id, :name => pet.name, :creature_type => pet.creature_type, :breed_bundle_id => pet.breed_bundle_id, :weight_grams => pet.weight_grams}
  end

end