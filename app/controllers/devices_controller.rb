class DevicesController < AuthenticatedController

  include MongoIdHelper

  #
  # Note: This filter will do a downstream request to the auth service to
  # check that there is an external user sign-in for the auth token
  #
  before_action :ensure_authenticated
  before_action :ensure_internal_user

  #######################################################
  # EXAMPLE LOCAL:
  # curl -v -X POST http://127.0.0.1:3000/device -H "Accept: application/json" -H "Content-Type: application/json"  -H "X-User-Token: qjWSpXyqmvvQnqM8Ujpn" -d '{"serial":"234234DTWERTSDF"}'
  #######################################################
  def create

    device_args = request.params[:device]

    # Give a 409 if there is already a device with this serial number
    existing_device = Device.where(serial: device_args[:serial]).exists?
    if(existing_device)
      render :status => 409, :json => {:error => I18n.t("409response")}
      return
    end

    device = Device.create(
        serial: device_args[:serial]
    )

    #
    # If the object fails validation, give a 422 error
    # If anything else fails, give 500 error
    #

    if(!device.valid?)
      handle_mongoid_validation_error(device, device_args)
      return
    end

    begin
      device.save!
    rescue => e
      logger.error "Unexpected error when saving document #{device_args}, error: #{e.inspect}"
      render :status => 500, :json => {:error => I18n.t("500response_internal_server_error")}
    end

    # Success 201
    render :status => 201, :json => {:serial => device.serial}
  end


  #######################################################
  # Register a device. This creates a mapping between
  # a pet, a user and a device.
  #
  # 401:
  # - Authentication failed - user is not logged in
  # - Authorization failed - user is not owner of the pet
  #
  # 404:
  # - A device matching the device id could not be found
  #
  # 409:
  # - Another device has already been registered for this pet
  # - This device has already been registered for another pet
  #
  # 500:
  # - An unexpected error occurred while creating the
  #   device registration
  #
  # EXAMPLE LOCAL:
  # curl -v -X POST http://127.0.0.1:3000/device/registration -H "Accept: application/json" -H "Content-Type: application/json"  -H "X-User-Token: qjWSpXyqmvvQnqM8Ujpn" -d '{"device_id":"234234DTWERTSDF","pet_id":"9d855750-db24-4f15-805b-aaf0309980b9"}'
  #######################################################
  def register_device
    # TODO
    head 204
  end

end