module MapLayers
  # Provides methods to generate HTML tags and JavaScript code
  module ViewHelpers
    # Insert javascript include tags
    #
    # options[:google] with GMAPS Key: Include Google Maps
    # options[:multimap]: Include MultiMap
    # options[:openstreetmap]: Include VirtualEarth
    # options[:virtualearth]: Include VirtualEarth
    # options[:yahoo]: Include Yahoo! Maps
    def map_layers_includes(options = {})
      options.assert_valid_keys(:google, :multimap, :openstreetmap, :virtualearth, :yahoo)
      html = ''
      if options.has_key?(:google)
        html << javascript_include_tag("http://maps.google.com/maps?file=api&amp;v=2&amp;key=#{options[:google]}")
      end
      if options.has_key?(:multimap)
        html << javascript_include_tag("http://clients.multimap.com/API/maps/1.1/metacarta_04")
      end
      if options.has_key?(:virtualearth)
        html << javascript_include_tag("http://dev.virtualearth.net/mapcontrol/v3/mapcontrol.js")
      end
      if options.has_key?(:yahoo)
        html << javascript_include_tag("http://api.maps.yahoo.com/ajaxymap?v=3.0&appid=euzuro-openlayers")
      end
      
      if RAILS_ENV == "development" && File.exist?(File.join(RAILS_ROOT, 'public/javascripts/lib/OpenLayers.js'))
        html << '<script src="/javascripts/lib/Firebug/firebug.js"></script>'
        html << '<script src="/javascripts/lib/OpenLayers.js"></script>'
      else
        html << javascript_include_tag('OpenLayers')
      end

      html << stylesheet_link_tag("map")
      html << javascript_tag("OpenLayers.ImgPath='/images/OpenLayers/';")
      html << javascript_tag(<<EOS
       function osm_getTileURL(bounds) {
          var res = this.map.getResolution();
          var x = Math.round((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
          var y = Math.round((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
          var z = this.map.getZoom();
          var limit = Math.pow(2, z);

          if (y < 0 || y >= limit) {
              return OpenLayers.Util.getImagesLocation() + "404.png";
          } else {
              x = ((x % limit) + limit) % limit;            
              return this.url + z + "/" + x + "/" + y + "." + this.type;
          }
      }
EOS
      ) if options.has_key?(:openstreetmap)

      html
    end
  end
end
