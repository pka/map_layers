module MapLayers
    module ViewHelpers
      def map_layers_includes(options = {})
        if RAILS_ENV == "development"
          js = javascript_include_tag('/lib/Firebug/firebug.js')
          js << javascript_include_tag('/lib/OpenLayers.js')
        else
          js = javascript_include_tag('OpenLayers')
        end
#        case options
#        when 'Google'
#          js << javascript_include_tag("http://maps.google.com/maps?file=api&amp;v=2&amp;key=#{gmaps_key}")
#        when 'VirtualEarth'
#          js << javascript_include_tag("http://dev.virtualearth.net/mapcontrol/v3/mapcontrol.js")
#        when 'Yahoo'
#          js << javascript_include_tag("http://api.maps.yahoo.com/ajaxymap?v=3.0&appid=euzuro-openlayers")
#        when 'MultiMap'
#          js << javascript_include_tag("http://clients.multimap.com/API/maps/1.1/metacarta_04")
#        end
        js << stylesheet_link_tag("map")
        js << javascript_tag("OpenLayers.ImgPath='/images/OpenLayers/';")

        js
      end
    end
end
