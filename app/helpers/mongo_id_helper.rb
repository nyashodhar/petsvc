module MongoIdHelper

  def handle_mongoid_validation_error(document, args=nil)

    if(args.blank?)
      if(document.errors.messages.blank?)
        logger.error "handle_mongoid_validation_error(): Validation error in doc #{document}, but the document contains no error message, error #{e.inspect}"
        render :status => 422, :json => {:error => I18n.t("422response")}
        return
      else
        logger.error "handle_mongoid_validation_error(): Validation error for doc: #{document.errors.messages}"
        # Note: The error message should already by localized via the spec in the mongoid object itself.
        render :status => 422, :json => {:error => document.errors.messages}
        return
      end
    else
      if(document.errors.messages.blank?)
        logger.error "handle_mongoid_validation_error(): Mongoid validation error occurred, but the document contains no error message, error #{e.inspect}, args #{args}"
        render :status => 422, :json => {:error => I18n.t("422response")}
        return
      else
        logger.error "handle_mongoid_validation_error(): Validation error: #{document.errors.messages}, args = #{args}"
        # Note: The error message should already by localized via the spec in the mongoid object itself.
        render :status => 422, :json => {:error => document.errors.messages}
        return
      end
    end

  end

end