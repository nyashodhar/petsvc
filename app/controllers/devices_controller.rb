class DevicesController < AuthenticatedController

  include MongoIdHelper

  #
  # Note: This filter will do a downstream request to the auth service to
  # check that there is an external user sign-in for the auth token
  #
  before_action :ensure_authenticated
  before_action :ensure_internal_user, only: [:create]
  before_action :resolve_pet_id_from_device_registration, only: [:deregister_device]
  before_action :ensure_owner_of_pet, only: [:register_device, :deregister_device]

  #######################################################
  # EXAMPLE LOCAL:
  # curl -v -X POST http://127.0.0.1:3000/device -H "Accept: application/json" -H "Content-Type: application/json"  -H "X-User-Token: KBbFPZGrFQvGPyduhzJG" -d '{"serial":"234234DTWERTSDH"}'
  #######################################################
  def create

    device_args = request.params[:device]

    existing_device = Device.where(serial: device_args[:serial]).exists?
    if(existing_device)
      logger.error "create(): Unable to create new device - a device with id #{device_args[:serial]} already exists, user #{@authenticated_email}:#{@authenticated_user_id}, args #{device_args}"
      render :status => 409, :json => {:error => I18n.t("409response")}
      return
    end

    begin
      device = Device.create(
          serial: device_args[:serial]
      )
      if(!device.valid?)
        handle_mongoid_validation_error(device, device_args)
        return
      end
      device.save!
    rescue => e
      logger.error "Unexpected error when creating device, args #{device_args}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    # Success 201
    render :status => 201, :json => {:serial => device.serial}
  end


  #######################################################
  # Register a device. This creates a mapping between
  # a pet, the currently logged in user and a device.
  #
  # 401:
  # - Authentication failed - user is not logged in
  # - Authorization failed - user is not an owner of the pet to which the device is being registered
  #
  # 404:
  # - A device matching the device id could not be found
  #
  # 409:
  # - Another device has already been registered for this pet
  # - This device has already been registered for another pet
  #
  # 422:
  # - Device id is missing
  #
  # 500:
  # - An unexpected error occurred while creating the device registration
  #
  # EXAMPLE LOCAL:
  # curl -v -X POST http://127.0.0.1:3000/device/registration -H "Accept: application/json" -H "Content-Type: application/json"  -H "X-User-Token: XfDpsGajFXvrYzzZwCzE" -d '{"device_id":"234234DTWERTSDF","pet_id":"0bf1afea-50b6-4bf6-a1c9-600796a39744"}'
  #######################################################
  def register_device

    device_id = request.params[:device_id]
    if(device_id.blank?)
      logger.error "register_device(): No device_id provided, logged in user (#{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 422, :json => {:error => I18n.t("422response")}
      return
    end

    begin
      device = Device.find_by(serial: device_id)
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error "register_device(): No device found for device_id #{device_id}, logged in user (#{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 404, :json => {:error => I18n.t("404response_resource_not_found")}
      return
    end

    # Has this device already been registered?
    if(!device.pet_id.blank? || !device.user_id.blank?)

      # If the device happens to be registered for the exact same pet and user, avoid the 409
      if(device.pet_id.eql?(@owned_pet.pet_id) && (device.user_id.to_i == @authenticated_user_id.to_i))
        logger.info "register_device(): Special case - This device (#{device.serial}) has already been registered for the pet and user in this request, no action required, logged in user (#{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
        render :status => 201, :json => {:serial => device.serial, :pet_id => device.pet_id, :user_id => device.user_id}
        return
      end

      # This device has been registered and (user_id, pet_id) does not match combo in our request
      logger.error "register_device(): This device (#{device.serial}) has already been registered for pet (#{device.pet_id}) for user #{device.user_id}, logged in user (#{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 409, :json => {:error => I18n.t("409response")}
      return
    else
      logger.info "register_device(): Good news - This device (#{device_id}) is not already registered to any pet"
    end

    # Has another device already been registered for this pet?
    begin
      device_already_registered_for_this_pet = Device.find_by(pet_id: @owned_pet.pet_id)
      logger.error "register_device(): A device (#{device_already_registered_for_this_pet.serial}) is already registered for this pet (#{@owned_pet.pet_id}) for user #{device_already_registered_for_this_pet.user_id}, logged in user (#{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 409, :json => {:error => I18n.t("409response")}
      return
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.info "register_device(): Good news - No other device is already registered for pet #{@owned_pet.pet_id}"
    end

    #
    # This device is not already registered, and another device is also not registered for this pet
    # Proceed and register the device to this pet and user
    #

    device.user_id = @authenticated_user_id
    device.pet_id = @owned_pet.pet_id

    begin
      device.save!
    rescue => e
      logger.error "register_device(): Unexpected error when registering device #{device.serial} for pet #{@owned_pet.pet_id} and user #{@authenticated_user_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    logger.info "register_device(): Device #{device.serial} was registered for pet #{@owned_pet.pet_id} and user #{@authenticated_user_id}"

    render :status => 201, :json => {:serial => device.serial, :pet_id => device.pet_id, :user_id => device.user_id}
  end


  #######################################################
  # Deregister a device. This removes the registered user id
  # and the registered pet id from a device document.
  #
  # 401:
  # - Authentication failed - user is not logged in
  # - No device found for device id
  # - The device is not registered, making pet-id authorization impossible
  # - No device found for device id, making pet ownership authorization impossible
  # - Authorization failed - user is not an owner of the pet to which the device is registered
  #
  # 422:
  # - Device id is missing from request
  #
  # 500:
  # - The device is registered but has no user id
  # - The device is registered but has no pet id
  # - An unexpected error occurred when saving the device after deregistering it
  #
  # EXAMPLE LOCAL:
  # curl -v -X DELETE http://127.0.0.1:3000/device/registration/234234DTWERTSDF -H "Accept: application/json" -H "Content-Type: application/json"  -H "X-User-Token: XfDpsGajFXvrYzzZwCzE"
  #######################################################
  def deregister_device

    #
    # Note: The authorization filter has already resolved the existence of a device
    # and the logged in user is the owner of the pet to which the device is registered.
    #
    # At this point we simply need to deregister the device.
    #

    @device_resolved_from_request.unset(:user_id)
    @device_resolved_from_request.unset(:pet_id)

    begin
      @device_resolved_from_request.save!
    rescue => e
      logger.error "deregister_device(): Unexpected error when deregistering device #{@device_resolved_from_request.serial} for pet #{@owned_pet.pet_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    logger.info "deregister_device(): device #{@device_resolved_from_request.serial} was deregistered for pet #{@owned_pet.pet_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}"
    head 204
  end

end