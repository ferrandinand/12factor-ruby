require 'net/https'
require 'json'
require 'sinatra/activerecord'
require 'logger'

class RandomPeople

    def initialize
      $LOG = Logger.new(STDOUT)
      $LOG.info "Starting application"
    end

    def add_country(country_name)
      $LOG.info "Creating country #{country_name}"
      country = Countries.new
      country.name = country_name
      country.visits = 0
      country.save
      $LOG.info "Created country #{country_name}"
    end

    def add_visit(country_name)

      add_country(country_name) unless Countries.exists?(name: country_name)

      country = Countries.find_by(name: country_name)
      country.visits += 1
      country.save
      $LOG.info "Updated country #{country_name}"
    end

    def person_provider(country)

 	    http = Net::HTTP.new('uinames.com')

      begin
        response = http.request(Net::HTTP::Get.new("/api/?ext&region=#{country}"))
        person = JSON.parse(response.body)
      rescue => e
        $LOG.warn 'Got some error getting the JSON file ' + response
      end
      return person
    end

    def person_name(person)
      person["name"]
    end

    def person_surname(person)
      person["surname"]
    end

    def person_image(person)
      person["photo"].to_s
    end
end

