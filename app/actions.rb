require_relative '../lib/pick_name.rb'
require_relative '../lib/app_signals.rb'

get '/:country' do

  @country = "#{params['country']}"
  return "Bad request" if @country.include? "."

  People = RandomPeople.new

  person = People.person_provider(@country)
  People.add_visit(@country) unless person.nil?

  @person_name = People.person_name(person)
  @person_surname = People.person_surname(person)
  @person_image = People.person_image(person)

  erb :index

end

