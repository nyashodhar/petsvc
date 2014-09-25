class DevicesController < AuthenticatedController

  #
  # Note: This filter will do a downstream request to the auth service to
  # check that there is an external user sign-in for the auth token
  #
  before_action :ensure_authorized_internal

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

    begin
      device.save!
    rescue Mongoid::Errors::Validations => e

      if(e.document.errors.messages.blank?)
        logger.error "Validation error occured when saving device #{device_args}, but the document contains no error message, error #{e.inspect}"
        render :status => 422, :json => {:error => I18n.t("422response")}
        return
      else

        logger.error "Error when saving device #{device_args}, error: #{e.document.errors.messages}\n"

        #
        # Note: The error message should already by localized via the spec
        # in the mongoid object itself.
        #
        render :status => 422, :json => {:error => e.document.errors.messages}
        return
      end

    rescue => e
      logger.error "Unexpected error when saving device #{device_args}, error: #{e.inspect}\n"
      render :status => 500, :json => {:error => I18n.t("500response")}
    end

    # Success 201

    render :status => 201, :json => {:serial => device.serial}

  end

end