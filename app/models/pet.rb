
=begin

##############################
# NOTES: ON PETS
##############################

Pet:
=====
id
name
birth_year
creature_type
breed
weight
image
device_serial
creator
owner_user_ids
owner_invitation_tokens

RULES:
- API for pet can be accessed by both creator and users in the owner_user_ids list
- The operation to register a device for a pet can be done by either the creator or an owner
- A pet can have only 1 device registered
- To register another device for a pet, the old one has to be unregistered first
- The creator or the owner can invite additional owners for the pet
- Only the pet creator can remove the pet
- The users that are in the owners list can remove themselves as owner for the pet,
  but the pet is then still available for the creator and the other users
- The max number of owners for a pet is 100 users

=end

class Pet

  #
  # TODO: Create mongoid spec for the Pet object here
  #

end