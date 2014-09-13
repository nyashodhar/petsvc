##################################################################
#
# Initialize the connection to mongo db.
#
##################################################################

require 'mongo'

include Mongo
include MongoLoader

the_environment = Rails.env.to_str
load_mongo(the_environment)
