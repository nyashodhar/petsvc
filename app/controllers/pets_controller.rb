class PetsController < AuthenticatedController

  include MongoIdHelper
  include PetBreedHelper

  before_action :ensure_authenticated
  before_action :ensure_owner_of_pet, only: [:update_pet, :get_owned_pet_for_logged_in_user]

  #######################################################
  # Creates a new pet object. When the pet object has
  # successfully created, a pet ownership object is created
  # to record that the user is an owner of the pet that
  # has been created.
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
  # curl -v -X POST http://127.0.0.1:3000/pet -H "Accept: application/json" -H "Content-Type: application/json" -H "X-User-Token: Xa6yCYdG_XNdDuEGjZry" -d '{"name":"Rotty the Rottweiler","birth_year":2012,"creature_type":0,"breed_bundle_id":"dog1","weight_grams":5100}'
  #######################################################
  def create_pet

    pet_args = request.params[:pet]

    if(!creature_type_and_breed_valid_on_create?(pet_args[:creature_type], pet_args[:breed_bundle_id], pet_args))
      return
    end

    pet = Pet.create(
        pet_id: SecureRandom.uuid,
        name: pet_args[:name],
        birth_year: pet_args[:birth_year],
        creature_type: pet_args[:creature_type],
        breed_bundle_id: pet_args[:breed_bundle_id],
        weight_grams: pet_args[:weight_grams]
    )

    #
    # If the object fails mongoid validation, give a 422 error
    # If anything else fails, give 500 error
    #

    if(!pet.valid?)
      handle_mongoid_validation_error(pet, pet_args)
      return
    end

    begin
      pet.save!
    rescue => e
      logger.error "create_pet(): Unexpected error when saving pet from args #{pet_args}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    #
    # The pet object was created, create a pet ownership
    #

    if(@authenticated_user_id.blank?)
      logger.error "create_pet(): No authenticated user id present => unable to create pet ownership"
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

    begin
      pet_ownership.save!
    rescue => e
      logger.error "create_pet(): Unexpected error when saving pet ownership for pet #{pet.pet_id}, user #{@authenticated_email}:#{@authenticated_user_id}, pet_args #{pet_args}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    logger.info "create_pet(): Pet #{pet.pet_id} created by user #{@authenticated_email}:#{@authenticated_user_id}"
    render :status => 201, :json => {:pet_id => pet.pet_id, :name => pet.name, :creature_type => pet.creature_type, :breed_bundle_id => pet.breed_bundle_id, :weight_grams => pet.weight_grams}
  end


  #######################################################
  # Updates an existing pet object.
  #
  # 401:
  #  - Authenticated failed - user not logged in
  #  - Authorization failed - the logged in user is not owner of the pet
  # 422:
  #  - One or more of the fields in the pet object were invalid
  # 500:
  #  - An unexpected error occurred while updating the pet object
  #
  # EXAMPLE LOCAL:
  # curl -v -X PUT http://127.0.0.1:3000/pet/0bf1afea-50b6-4bf6-a1c9-600796a39744 -H "Accept: application/json" -H "Content-Type: application/json" -H "X-User-Token: XfDpsGajFXvrYzzZwCzE" -d '{"name":"Fido","birth_year":2012,"creature_type":0,"breed_bundle_id":"dog1","weight_grams":5100}'
  #######################################################
  def update_pet

    pet_args = request.params[:pet]

    #
    # Note that it's allowed for the client to only update a subset of all
    # the fields of a pet in a single request
    #

    if(!pet_args[:name].blank?)
      @owned_pet.name = pet_args[:name]
    end

    if(!pet_args[:birth_year].blank?)
      @owned_pet.birth_year = pet_args[:birth_year]
    end

    if(!creature_type_and_breed_valid_on_update?(pet_args[:creature_type], pet_args[:breed_bundle_id]))
      return
    end

    if(!pet_args[:breed_bundle_id].blank?)
      @owned_pet.breed_bundle_id = pet_args[:breed_bundle_id]
    end

    if(!pet_args[:creature_type].blank?)
      @owned_pet.creature_type = pet_args[:creature_type]
    end

    if(!pet_args[:weight_grams].blank?)
      @owned_pet.weight_grams = pet_args[:weight_grams]
    end

    begin
      @owned_pet.save!
    rescue => e
      logger.error "update_pet(): Unexpected error when updating pet #{@owned_pet.pet_id}. User #{@authenticated_email}:#{@authenticated_user_id}) - args #{pet_args} - error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    logger.info "update_pet(): Pet #{@owned_pet.pet_id} updated by user #{@authenticated_email}:#{@authenticated_user_id}"
    head 204
  end


  #######################################################
  # Remove the logged in user's ownership for a given pet id
  #
  # Since the existence of a pet ownership for the given
  # pet id is proof that the user is indeed currently an owner
  # of the pet, the 'ensure_owner_of_pet' filter is not applied
  # for this method.
  #
  # 401:
  #  - Authentication failed - user not logged in
  #
  # 404:
  #  - No pet ownership for the given pet was found for the
  #    logged in user
  #
  # 409:
  #  - A device registration for this pet by the logged in user
  #    exists. This registration must be removed before the
  #    user is allowed to remove the ownership for the pet.
  #
  # 500:
  #  - An unexpected error occurred while removing the pet
  #    ownership.
  #
  # EXAMPLE LOCAL:
  # curl -v -X DELETE http://127.0.0.1:3000/pet/0bf1afea-50b6-4bf6-a1c9-600796a39744/ownership -H "Accept: application/json" -H "Content-Type: application/json" -H "X-User-Token: Xa6yCYdG_XNdDuEGjZry"
  #######################################################
  def remove_pet_ownership_for_logged_in_user

    pet_id = params[:pet_id]

    begin
      pet_ownership = PetOwnership.find_by(user_id: @authenticated_user_id, pet_id: pet_id)
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error "remove_pet_ownership_for_logged_in_user(): No ownership for pet #{pet_id} was found for user #{@authenticated_email}:#{@authenticated_user_id}, ownership deletion not possible."
      render :status => 404, :json => {:error => I18n.t("404response_resource_not_found")}
      return
    end

    begin
      device_for_pet_by_user = Device.find_by(user_id: @authenticated_user_id, pet_id: pet_id)
      if(!device_for_pet_by_user.blank?)
        logger.error "remove_pet_ownership_for_logged_in_user(): Device #{device_for_pet_by_user.serial} is registered for pet #{pet_id} by user #{@authenticated_email}:#{@authenticated_user_id}, aborting pet ownership deletion."
        render :status => 409, :json => {:error => I18n.t("409response_device_registration_exists")}
        return
      end
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.info "remove_pet_ownership_for_logged_in_user(): No device is registered for pet #{pet_id} by user #{@authenticated_email}:#{@authenticated_user_id}, ownership deletion will be attempted."
    end

    begin
      pet_ownership.delete()
    rescue => e
      logger.error "remove_pet_ownership_for_logged_in_user(): Unexpected error when deleting pet ownership for pet #{pet_id} for user #{@authenticated_email}:#{@authenticated_user_id}, ownership deletion not possible, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    logger.error "remove_pet_ownership_for_logged_in_user(): Pet ownership removed for pet #{pet_id} for user #{@authenticated_email}:#{@authenticated_user_id}"
    head 204
  end


  #######################################################
  # Get the pet ids of all the pets owned by the logged
  # in users
  #
  # 401:
  #  - Authentication failed - user not logged in
  # 500:
  #  - An unexpected error occurred while fetching the pet ownerships
  #
  # EXAMPLE LOCAL:
  # curl -v -X GET http://127.0.0.1:3000/pet/ownership -H "Accept: application/json" -H "Content-Type: application/json" -H "X-User-Token: XfDpsGajFXvrYzzZwCzE"
  #######################################################
  def get_owned_pet_ids_for_logged_in_user

    owned_pet_ids = Array.new

    begin
      pet_ownerships = PetOwnership.where(user_id: @authenticated_user_id)
      pet_ownerships.to_a.each do |pet_ownership|
        owned_pet_ids.push(pet_ownership.pet_id)
      end
    rescue => e
      logger.error "get_owned_pet_ids_for_logged_in_user(): Unexpected error when querying for pet ownerships for user #{@authenticated_email}:#{@authenticated_user_id}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    logger.info "get_owned_pet_ids_for_logged_in_user(): Found #{owned_pet_ids.length} pet ids owned by user #{@authenticated_email}:#{@authenticated_user_id}"

    render :status => 200, :json => {:pet_ids => owned_pet_ids}
  end

  #######################################################
  # Get all the pets owned by the currently logged in user
  #
  # 401:
  #  - Authentication failed - user not logged in
  # 500:
  #  - An unexpected error occurred while fetching the owned pets
  #
  # EXAMPLE LOCAL:
  # curl -v -X GET http://127.0.0.1:3000/pet -H "Accept: application/json" -H "Content-Type: application/json" -H "X-User-Token: Xa6yCYdG_XNdDuEGjZry"
  #######################################################
  def get_owned_pets_for_logged_in_user

    owned_pet_ids = Array.new

    begin
      pet_ownerships = PetOwnership.where(user_id: @authenticated_user_id)
      pet_ownerships.to_a.each do |pet_ownership|
        owned_pet_ids.push(pet_ownership.pet_id)
      end
    rescue => e
      logger.error "get_owned_pets_for_logged_in_user(): Unexpected error when querying for pet ownerships for user #{@authenticated_email}:#{@authenticated_user_id}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    owned_pets = Array.new
    owned_pet_ids.each do | pet_id |
      begin
        pet = Pet.find_by(pet_id: pet_id)
        owned_pets.push({:pet_id => pet.pet_id, :name => pet.name, :creature_type => pet.creature_type, :breed_bundle_id => pet.breed_bundle_id, :weight_grams => pet.weight_grams})
      rescue Mongoid::Errors::DocumentNotFound => e
        logger.error "get_owned_pets_for_logged_in_user(): An ownership for pet #{pet_id} was found for user #{@authenticated_email}:#{@authenticated_user_id}, but the pet does not exist!"
        render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
        return
      end
    end

    logger.info "get_owned_pets_for_logged_in_user(): Found #{owned_pets.length} pets owned by user #{@authenticated_email}:#{@authenticated_user_id}"
    render :status => 200, :json => {:pets => owned_pets}
  end

  #######################################################
  # Get a pet for a given pet_id, the pet must be owned
  # by the logged in user.
  #
  # 401:
  # - Authenticated failed - user not logged in
  # - Authorization failed - user is not an owner of the pet identified by the pet id
  #
  # 500:
  # - An unexpected error occurred while fetching the pet
  #
  # EXAMPLE LOCAL:
  # curl -v -X GET http://127.0.0.1:3000/pet/f65e0337-cf9a-4a82-a415-bf84a26f504c -H "Accept: application/json" -H "Content-Type: application/json" -H "X-User-Token: Xa6yCYdG_XNdDuEGjZry"
  #######################################################
  def get_owned_pet_for_logged_in_user
    logger.info "get_owned_pet_for_logged_in_user(): Found pet #{@owned_pet.pet_id} owned by user #{@authenticated_email}:#{@authenticated_user_id}"
    render :status => 200, :json => {:pet_id => @owned_pet.pet_id, :name => @owned_pet.name, :creature_type => @owned_pet.creature_type, :breed_bundle_id => @owned_pet.breed_bundle_id, :weight_grams => @owned_pet.weight_grams}
  end

end