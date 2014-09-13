#
# Add initializer for mongo
# Used in both migrate_mongo task and actual app initialization
#

module MongoLoader

  def load_mongo(the_environment)

    config_file = "#{Rails.root}/config/mongo.yml"
    mongo_yaml = YAML::load_file(config_file)

    mongo_info = mongo_yaml[the_environment]
    unless mongo_info['dbhost']
      STDOUT.write "=> ERROR in Mongo initializer: dbhost not specified for env #{the_environment} in #{config_file}\n"
      exit
    end

    unless mongo_info['dbport']
      STDOUT.write "=> ERROR in Mongo initializer: dbport not specified for env #{the_environment} in #{config_file}\n"
      exit
    end

    unless mongo_info['dbname']
      STDOUT.write "=> ERROR in Mongo initializer: dbname not specified for env #{the_environment} in #{config_file}\n"
      exit
    end

    unless mongo_info['pets_collection']
      STDOUT.write "=> ERROR in Mongo initializer: migrations_collection not specified for env #{the_environment} in #{config_file}\n"
      exit
    end

    unless mongo_info['migrations_collection']
      STDOUT.write "=> ERROR in Mongo initializer: pets_collection not specified for env #{the_environment} in #{config_file}\n"
      exit
    end

    dbhost = mongo_info['dbhost']
    dbport = mongo_info['dbport']
    dbname = mongo_info['dbname']
    migrations_collection = mongo_info['migrations_collection']
    pets_collection = mongo_info['pets_collection']

    begin

      $mongo_client = MongoClient.new(dbhost, dbport)
      $mongo_db = $mongo_client.db(dbname)
      $pets_coll = $mongo_db.collection(pets_collection)
      $migrations_coll = $mongo_db.collection(migrations_collection)

      #
      # This is needed for the drop_mongo rake task.
      # The drop operation is done by passing the name of the db
      # to the mongo client. Making this a global var makes it
      # possible to access the actual dbname later.
      #
      $mongo_config = mongo_info.clone
      STDOUT.write "=> Mongo initializer: Env: #{the_environment}, connected to #{dbhost}:#{dbport}, db: #{dbname}, pets_collection: #{pets_collection}, migrations_collection: #{migrations_collection}\n"

    rescue => e
      trace = e.backtrace[0,10].join("\n")
      STDOUT.write "=> ERROR in Mongo initializer: Env: #{the_environment}, could not connect to #{dbhost}:#{dbport}, db: #{dbname}, pets_collection: #{pets_collection}, migrations_collection: #{migrations_collection} - #{e.inspect} - TRACE: #{trace}\n"
      exit
    end

  end

end