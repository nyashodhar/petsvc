class DevicesController < ActionController::Base

  #######################################################
  # EXAMPLE LOCAL:
  # curl -v -X POST http://127.0.0.1:3000/device -H "Accept: application/json" -H "Content-Type: application/json" -d '{"serial":"234234DTWERTSDF"}'
  #######################################################
  def create

    device_args = request.params[:device]

    device = Device.create(
        serial: device_args[:serial]
    )

    #
    # TODO: Give 409 CONFLICT if a device with serial number already exists..
    #

    result = device.save!

    # For now, just give a success response with no content
    head :no_content
  end

end