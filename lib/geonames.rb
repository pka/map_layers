# GeoNames REST services
# 
# http://www.geonames.org/export/web-services.html
#
module Geonames

  module JsonFormat # :nodoc:
    extend self

    def extension
      "json"
    end

    def mime_type
      "application/json"
    end

    def encode(hash)
      hash.to_json
    end

    def decode(json)
      h = ActiveSupport::JSON.decode(json)
      h.values.flatten # Return type must be an array of hashes
    end
  end

  # GeoNames REST services base class
  class GeonamesResource < ActiveResource::Base
    self.site = "http://ws.geonames.org/"
    self.format = JsonFormat
  end

  # GeoNames Postalode REST services
  class Postalcode < GeonamesResource
    # Postal code search
    # 
    # http://www.geonames.org/export/web-services.html#postalCodeSearch
    #
    def self.search(placename, options = {:maxRows => 50})
      self.find(:all, :from => "/postalCodeSearchJSON", :params => { :placename => placename }.merge(options))
    end
  end

  # GeoNames Weather REST services
  class Weather < GeonamesResource
    # Weather stations with the most recent weather observation
    # 
    # Example: Geonames::Weather.weather(:north => 44.1, :south => -9.9, :east => -22.4, :west => 55.2)
    # 
    # http://www.geonames.org/export/JSON-webservices.html#weatherJSON
    #
    def self.weather(options)
      self.find(:all, :from => "/weatherJSON", :params => options)
    end

    # Weather station and the most recent weather observation for the ICAO code
    # 
    # http://www.geonames.org/export/JSON-webservices.html#weatherIcaoJSON
    #
    def self.weatherIcao(icao, options = {})
      self.find(:all, :from => "/weatherIcaoJSON", :params => { :ICAO => icao }.merge(options))
    end
  end
 
end
