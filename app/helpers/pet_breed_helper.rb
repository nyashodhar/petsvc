module PetBreedHelper

  ####################################################
  #
  # The values of the fields creature_type and breed_bundle_id
  # are interdependent. This method validates that the
  # values specified during the creation of a new pet are
  # valid and compatible.
  #
  # If any validation fails, this method will render a
  # 422 with errors to the client and return false.
  #
  # If no problem was found during validation, this
  # method returns true.
  #
  ####################################################
  def creature_type_and_breed_valid_on_create?(creature_type, breed_bundle_id, pet_args)

    creature_type_missing = creature_type.blank?
    breed_bundle_id_missing = breed_bundle_id.blank?

    if(creature_type_missing || breed_bundle_id_missing)

      errors_hash = Hash.new
      if(creature_type_missing)
        logger.error "creature_type_and_breed_valid_on_create?(): creature_type type was not specified when creating a new pet (pet_args = #{pet_args}, logged in user = #{@authenticated_email}:#{@authenticated_user_id})"
        errors_hash[:creature_type] = [I18n.t("field_is_required")]
      end

      if(breed_bundle_id_missing)
        logger.error "creature_type_and_breed_valid_on_create?(): breed_bundle_id type was not specified when creating a new pet (pet_args = #{pet_args}, logged in user = #{@authenticated_email}:#{@authenticated_user_id})"
        errors_hash[:breed_bundle_id] = [I18n.t("field_is_required")]
      end

      render :status => 422, :json => {:error => errors_hash}
      return false
    end

    #
    # Both creature_type and breed_bundle_id is specified.
    # Give error if the creature_type is not compatible with the breed_bundle_id
    #

    if(!breed_bundle_id_compatible_with_creature_type?(breed_bundle_id, creature_type))
      logger.error "creature_type_and_breed_valid_on_create?(): The breed_bundle_id #{breed_bundle_id} is incompatible with the creature type #{creature_type} (pet_args = #{pet_args}, logged in user = #{@authenticated_email}:#{@authenticated_user_id})"
      errors_hash = {:breed_bundle_id => [I18n.t("breed_bundle_id_incompatible_with_creature_type")], :creature_type => [I18n.t("creature_type_incompatible_with_breed")]}
      render :status => 422, :json => {:error => errors_hash}
      return false
    end

    #
    # The breed_bundle_id and creature_type are compatible based on prefix.
    # Final check is to ensure that the breed_bundle_id truly exists in the resource bundle
    #

    if(!breed_bundle_id_exists_in_resource_bundle?(creature_type, breed_bundle_id))
      logger.error "creature_type_and_breed_valid_on_create?(): The breed_bundle_id #{breed_bundle_id} was not found in the resource bundle (pet_args = #{pet_args}, logged in user = #{@authenticated_email}:#{@authenticated_user_id})"
      errors_hash = {:breed_bundle_id => [I18n.t("breed_bundle_id_could_not_be_resolved")]}
      render :status => 422, :json => {:error => errors_hash}
      return false
    end

    return true

  end


  ####################################################
  #
  # The values of the fields creature_type and breed_bundle_id
  # are interdependent. This method validates that the
  # values specified during the update of an existing pet are
  # valid and compatible.
  #
  # If any validation fails, this method will render a
  # 422 with errors to the client and return false.
  #
  # If no problem was found during validation, this
  # method returns true.
  #
  ####################################################
  def creature_type_and_breed_valid_on_update?(creature_type, breed_bundle_id)

    if(!creature_type.blank? && breed_bundle_id.blank?)

      #
      # We have a creature_type, but breed_bundle_id is not specified.
      # Give error if creature type is changing since it would result in
      # incompatible breed_bundle_id..
      #

      if(@owned_pet.creature_type.to_i != creature_type.to_i)
        logger.error "creature_type_and_breed_valid_on_update?(): The new creature type #{creature_type} is different from the old creature type #{@owned_pet.creature_type} but breed_bundle_id is not specified (pet_id = #{@owned_pet.pet_id}, logged in user = #{@authenticated_email}:#{@authenticated_user_id})"
        errors_hash = {:creature_type => [I18n.t("creature_type_incompatible_with_breed")]}
        render :status => 422, :json => {:error => errors_hash}
        return false
      end
    end

    if(creature_type.blank? && !breed_bundle_id.blank?)

      #
      # breed_bundle_id is specified, but not creature type
      # Give error if the new breed_bundle_id is not compatible with
      # the existing creature type
      #

      if(!breed_bundle_id_compatible_with_creature_type?(breed_bundle_id, @owned_pet.creature_type))
        logger.error "creature_type_and_breed_valid_on_update?(): The new breed_bundle_id #{breed_bundle_id} is incompatible with the existing creature type #{@owned_pet.creature_type} (pet_id = #{@owned_pet.pet_id}, logged in user = #{@authenticated_email}:#{@authenticated_user_id})"
        errors_hash = {:breed_bundle_id => [I18n.t("breed_bundle_id_incompatible_with_creature_type")]}
        render :status => 422, :json => {:error => errors_hash}
        return false
      end
    end

    if(!creature_type.blank? && !breed_bundle_id.blank?)

      #
      # Both creature_type and breed_bundle_id is specified.
      # Give error if the new creature_type is not compatible with the new breed_bundle_id
      #

      if(!breed_bundle_id_compatible_with_creature_type?(breed_bundle_id, creature_type))
        logger.error "creature_type_and_breed_valid_on_update?(): The new breed_bundle_id #{breed_bundle_id} is incompatible with the new creature type #{creature_type} (pet_id = #{@owned_pet.pet_id}, logged in user = #{@authenticated_email}:#{@authenticated_user_id})"
        errors_hash = {:breed_bundle_id => [I18n.t("breed_bundle_id_incompatible_with_creature_type")], :creature_type => [I18n.t("creature_type_incompatible_with_breed")]}
        render :status => 422, :json => {:error => errors_hash}
        return false
      end

      #
      # The breed_bundle_id and creature_type are compatible based on prefix.
      # Final check is to ensure that the breed_bundle_id truly exists in the resource bundle
      #

      if(!breed_bundle_id_exists_in_resource_bundle?(creature_type, breed_bundle_id))
        logger.error "creature_type_and_breed_valid_on_update?(): The new breed_bundle_id #{breed_bundle_id} was not found in the resource bundle (pet_id = #{@owned_pet.pet_id}, logged in user = #{@authenticated_email}:#{@authenticated_user_id})"
        errors_hash = {:breed_bundle_id => [I18n.t("breed_bundle_id_could_not_be_resolved")]}
        render :status => 422, :json => {:error => errors_hash}
        return false
      end

    end

    return true

  end


  private

  def breed_bundle_id_compatible_with_creature_type?(breed_bundle_id, creature_type)

    if(creature_type.to_i != 0 && creature_type.to_i != 1)
      logger.error "breed_bundle_id_compatible_with_creature_type?(): Invalid value creature type value #{creature_type}"
      return false
    end

    breed_bundle_prefix = get_breed_bundle_prefix_for_creature_type(creature_type)

    if(breed_bundle_id.to_s.start_with?(breed_bundle_prefix))
      return true
    end

    return false
  end

  def get_breed_bundle_prefix_for_creature_type(creature_type)

    if(creature_type.to_i == 0)
      return "dog"
    end

    if(creature_type.to_i == 1)
      return "cat"
    end
  end

  #
  # TODO: This method should just be replaced by simple looking in I18n
  #

  def breed_bundle_id_exists_in_resource_bundle?(creature_type, breed_bundle_id)

    if(creature_type.to_i == 0)
      return $dog_breeds.include?(breed_bundle_id.to_s.downcase)
    end

    if(creature_type.to_i == 1)
      return $cat_breeds.include?(breed_bundle_id.to_s.downcase)
    end

    logger.error "breed_bundle_id_exists_in_resource_bundle?(): Invalid creature type #{creature_type}"
    return false
  end

end