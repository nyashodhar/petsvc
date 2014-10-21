class DevicesController < AuthenticatedController

  include MongoIdHelper

  before_action :ensure_authenticated
  before_action :ensure_internal_user, only: [:create_device_as_internal_user]
  before_action :resolve_pet_id_from_device_registration, only: [:deregister_device]
  before_action :ensure_owner_of_pet, only: [:register_device_for_logged_in_user, :deregister_device, :get_device_registration_for_pet]

  #######################################################
  # Create a device. The logged in user must be an internal user
  #
  # 401:
  # - Authentication failed - user is not logged in
  # - Authorization failed - the user is not an internal user
  #
  # 409:
  # - A device with the given device id already exists
  #
  # 422:
  # - Device id is missing from request
  # - Mongoid validation error
  #
  # 500:
  # - Unexpected error while storing creating the device
  #
  # EXAMPLE LOCAL:
  # curl -v -X POST http://127.0.0.1:3000/device -H "Accept: application/json" -H "Content-Type: application/json"  -H "X-User-Token: WZJK3VUF3-SwrqasCxGD" -d '{"device_id":"234234DTWERTSDH","device_type":"TRACKER","device_version":"0.1"}'
  #######################################################
  def create_device_as_internal_user

    device_id = params[:device_id]
    if(device_id.blank?)
      logger.error "create_device_as_internal_user(): No device_id provided, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      errors_hash = {:device_id => [I18n.t("field_is_required")]}
      render :status => 422, :json => {:error => errors_hash}
      return
    end

    existing_device = Device.where(device_id: device_id).exists?
    if(existing_device)
      logger.error "create_device_as_internal_user(): Unable to create new device - a device with id #{device_id} already exists, user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 409, :json => {:error => I18n.t("409response")}
      return
    end

    begin
      device = Device.create(
          device_id: device_id,
          device_type: params[:device_type],
          device_version: params[:device_version],
          creator_user_id: @authenticated_user_id,
          creation_time: Time.now
      )
      if(!device.valid?)
        handle_mongoid_validation_error(device, request.params)
        return
      end
      device.save!
    rescue => e
      logger.error "create_device_as_internal_user(): Unexpected error when creating device, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params #{request.params}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    logger.info "create_device_as_internal_user(): Device #{device_id} created by user #{@authenticated_email}:#{@authenticated_user_id}"
    render :status => 201, :json => {:device_id => device.device_id, :device_type => device.device_type, :device_version => device.device_version}
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
  # 412:
  # - This user has too many devices registered (TODO)
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
  # curl -v -X PUT http://127.0.0.1:3000/device/234234DTWERTSDH/registration -H "Accept: application/json" -H "Content-Type: application/json"  -H "X-User-Token: WZJK3VUF3-SwrqasCxGD" -d '{"pet_id":"9a7f1a9f-0f43-45bb-8602-46286c2c4ab0"}'
  #######################################################
  def register_device_for_logged_in_user

    device_id = params[:device_id]
    if(device_id.blank?)
      logger.error "register_device_for_logged_in_user(): No device_id provided, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      errors_hash = {:device_id => [I18n.t("field_is_required")]}
      render :status => 422, :json => {:error => errors_hash}
      return
    end

    begin
      device = Device.find_by(device_id: device_id)
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error "register_device_for_logged_in_user(): No device found for device_id #{device_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 404, :json => {:error => I18n.t("404response_resource_not_found")}
      return
    end

    # Has this device already been registered?
    if(!device.pet_id.blank? || !device.user_id.blank?)

      # If the device happens to be registered for the exact same pet and user, avoid the 409
      if(device.pet_id.eql?(@owned_pet.pet_id) && (device.user_id.to_i == @authenticated_user_id.to_i))
        logger.info "register_device_for_logged_in_user(): Special case - This device (#{device.device_id}) has already been registered for the pet and user in this request, no action required, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
        render :status => 201, :json => {:device_id => device.device_id, :pet_id => device.pet_id, :user_id => device.user_id}
        return
      end

      # This device has been registered and (user_id, pet_id) does not match combo in our request
      logger.error "register_device_for_logged_in_user(): This device (#{device.device_id}) has already been registered for pet (#{device.pet_id}) for user #{device.user_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 409, :json => {:error => I18n.t("409response")}
      return
    else
      logger.info "register_device_for_logged_in_user(): Good news - This device (#{device_id}) is not already registered to any pet"
    end

    # Has another device already been registered for this pet?
    begin
      device_already_registered_for_this_pet = Device.find_by(pet_id: @owned_pet.pet_id)
      logger.error "register_device_for_logged_in_user(): A device (#{device_already_registered_for_this_pet.device_id}) is already registered for this pet (#{@owned_pet.pet_id}) for user #{device_already_registered_for_this_pet.user_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 409, :json => {:error => I18n.t("409response")}
      return
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.info "register_device_for_logged_in_user(): Good news - No other device is already registered for pet #{@owned_pet.pet_id}"
    end

    #
    # This device is not already registered, and another device is also not registered for this pet
    # Proceed and register the device to this pet and user
    #

    device.user_id = @authenticated_user_id
    device.pet_id = @owned_pet.pet_id
    device.registration_time = Time.now

    begin
      device.save!
    rescue => e
      logger.error "register_device_for_logged_in_user(): Unexpected error when registering device #{device.device_id} for pet #{@owned_pet.pet_id} and user #{@authenticated_user_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    logger.info "register_device_for_logged_in_user(): Device #{device.device_id} was registered for pet #{@owned_pet.pet_id} and user #{@authenticated_user_id}"
    head 204
  end


  #######################################################
  # Deregister a device given a device id. This removes the registered user id
  # and the registered pet_id from that device document.
  #
  # 401:
  # - Authentication failed - user is not logged in
  # - Authorization failed - No device found for device id
  # - Authorization failed - The device is not registered, making pet ownership authorization impossible
  # - Authorization failed - No device found for device id, making pet ownership authorization impossible
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
  # curl -v -X DELETE http://127.0.0.1:3000/device/234234DTWERTSDH/registration -H "Accept: application/json" -H "Content-Type: application/json"  -H "X-User-Token: WZJK3VUF3-SwrqasCxGD"
  #######################################################
  def deregister_device

    #
    # Note: The authorization filter has already resolved the existence of a device
    # and the logged in user is the owner of the pet to which the device is registered.
    #
    # At this point we simply need to deregister the device.
    #

    # How to remove a field from a doc: https://coderwall.com/p/wcx4pq
    @device_resolved_from_request.unset(:user_id)
    @device_resolved_from_request.unset(:pet_id)
    @device_resolved_from_request.unset(:registration_time)

    begin
      @device_resolved_from_request.save!
    rescue => e
      logger.error "deregister_device(): Unexpected error when deregistering device #{@device_resolved_from_request.device_id} for pet #{@owned_pet.pet_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    logger.info "deregister_device(): device #{@device_resolved_from_request.device_id} was deregistered for pet #{@owned_pet.pet_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}"
    head 204
  end

  #######################################################
  # Get all the registered devices that belong to the
  # logged in user.
  #
  # It's assumed that it's not allowed for a user to remove
  # their ownership of a pet without first removing the
  # any device registration for that pet. Therefore, for this
  # call we will do any double check to verify the ownership
  # of each pet for which this user has a device registered.
  #
  # 401:
  # - Authentication failed - user is not logged in
  #
  # EXAMPLE LOCAL:
  # curl -v -X GET http://127.0.0.1:3000/device/registration -H "Accept: application/json" -H "Content-Type: application/json"  -H "X-User-Token: XfDpsGajFXvrYzzZwCzE"
  #######################################################
  def get_all_device_registrations_for_logged_in_user

    devices_for_response = Array.new

    begin
      registered_devices = Device.where(user_id: @authenticated_user_id)
      registered_devices.to_a.each do |registered_device|
        devices_for_response.push({:device_id => registered_device.device_id, :device_type => registered_device.device_type, :device_version => registered_device.device_version, :pet_id => registered_device.pet_id})
      end
    rescue => e
      logger.error "get_all_device_registrations_for_logged_in_user(): Unexpected error when querying for device registrations for user #{@authenticated_email}:#{@authenticated_user_id}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    logger.info "get_all_device_registrations_for_logged_in_user(): Found #{devices_for_response.length} device registrations for user #{@authenticated_email}:#{@authenticated_user_id}"
    render :status => 200, :json => {:devices => devices_for_response}
  end


  #######################################################
  # Get the device registration information for a given
  # pet.
  #
  # Note: If the pet has multiple owners, it's possible that
  # user id in the device registration is not the user id
  # of the currently logged in user. That's OK.
  #
  # 401:
  # - Authentication failed - user is not logged in
  # - Authorization failed - The logged in user is not an owner of the pet
  #
  # 404:
  # - No device registration is found for the pet
  #
  # 500:
  # - User id is missing from the device registered for the given pet id
  #
  # EXAMPLE LOCAL:
  # curl -v -X GET http://127.0.0.1:3000/device/registration/pet/0bf1afea-50b6-4bf6-a1c9-600796a39744 -H "Accept: application/json" -H "Content-Type: application/json"  -H "X-User-Token: XfDpsGajFXvrYzzZwCzE"
  #######################################################
  def get_device_registration_for_pet

    begin
      device = Device.find_by(pet_id: @owned_pet.pet_id)
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.info "get_device_registration_for_pet(): No device is registered for the pet #{@owned_pet.pet_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}"
      render :status => 404, :json => {:error => I18n.t("404response_resource_not_found")}
      return
    end

    if(device.user_id.blank?)
      logger.error "get_device_registration_for_pet(): The device #{device.device_id} appears to be registered, but has no user id. This should never happen, device = #{device.inspect}, logged in user #{@authenticated_email}:#{@authenticated_user_id}, request.params: #{request.params}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
      return
    end

    logger.info "get_device_registration_for_pet(): Device registration located for pet #{@owned_pet.pet_id}, device id #{device.device_id}, device registered to user #{device.user_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}"
    render :status => 200, :json => {:device_id => device.device_id, :device_type => device.device_type, :device_version => device.device_version, :pet_id => device.pet_id, :user_id => device.user_id}
  end

end