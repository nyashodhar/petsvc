################################################
#
# This initializer is used to hold the list of
# valid dog and cat breed bundle ids in memory for use
# during pet object validations.
#
# Note that this is not to be used for internationalization, only
# to be determine what bundle ids are actually valid (which is
# not possible to do easily by accessing the I18n object)
#
################################################

dog_breeds_en = "#{Rails.root}/config/locales/dogs_en.yml"
cat_breeds_en = "#{Rails.root}/config/locales/cats_en.yml"

#
# e.g., dog_breeds_en, will contain stuff like
#  {"en"=>{"dog1"=>"Abruzzenhund", "dog2"=>"Affenpinscher", "dog3"=>"Afghan Hound", "dog4"=>"Africanis", "dog5"=>"Aidi"}}
#

dog_breeds_yaml = YAML::load_file(dog_breeds_en)
$dog_breeds = Set.new(dog_breeds_yaml["en"].keys)

cat_breeds_yaml = YAML::load_file(cat_breeds_en)
$cat_breeds = Set.new(cat_breeds_yaml["en"].keys)

STDOUT.write "=> Pet Breeds Initializer: Loaded #{$dog_breeds.size} dog breed bundle ids and #{$cat_breeds.size} cat breed bundle ids from resource bundle\n"
