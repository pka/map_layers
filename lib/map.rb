require 'js_wrapper'
  
module MapLayers
  
  GOOGLE = Layer::Google.new("Google Street")
  GOOGLE_SATELLITE = Layer::Google.new("Google Satelite", {:type => :G_SATELLITE_MAP})
  GOOGLE_HYBRID = Layer::Google.new("Google Hybrid", {:type => :G_HYBRID_MAP})
  GOOGLE_PHYSICAL = Layer::Google.new("Google Physical", {:type => :G_PHYSICAL_MAP})
  VE_ROAD = Layer::VirtualEarth.new("Virtual Earth Raods", {:type => JsExpr.new('VEMapStyle.Road')})
  VE_AERIAL = Layer::VirtualEarth.new("Virtual Earth Aerial", {:type => JsExpr.new('VEMapStyle.Aerial')})
  VE_HYBRID = Layer::VirtualEarth.new("Virtual Earth Hybrid", {:type => JsExpr.new('VEMapStyle.Hybrid')})
  YAHOO =  Layer::Yahoo.new("Yahoo Street")
  YAHOO_SATELLITE = Layer::Yahoo.new("Yahoo Satelite", {:type => :YAHOO_MAP_SAT})
  YAHOO_HYBRID = Layer::Yahoo.new("Yahoo Hybrid", {:type => :YAHOO_MAP_HYB})
  MULTIMAP = Layer::MultiMap.new("MultiMap")
  OPENSTREETMAP = Layer::WMS.new("OpenStreetMap", 
    [
      "http://t1.hypercube.telascience.org/tiles?",
      "http://t2.hypercube.telascience.org/tiles?",
      "http://t3.hypercube.telascience.org/tiles?",
      "http://t4.hypercube.telascience.org/tiles?"
    ], 
    {:layers => 'osm-4326', :format => 'image/png' } )
  NASA_GLOBAL_MOSAIC = Layer::WMS.new("NASA Global Mosaic", 
    [
      "http://t1.hypercube.telascience.org/cgi-bin/landsat7",
      "http://t2.hypercube.telascience.org/cgi-bin/landsat7",
      "http://t3.hypercube.telascience.org/cgi-bin/landsat7",
      "http://t4.hypercube.telascience.org/cgi-bin/landsat7"
    ], 
    {:layers => 'landsat7'} )
  WORLDWIND = Layer::WorldWind.new("World Wind LANDSAT",
    "http://worldwind25.arc.nasa.gov/tile/tile.aspx", 2.25, 4, {:T => "105"}, {:tileSize => OpenLayers::Size.new(512,512)})
  WORLDWIND_URBAN = Layer::WorldWind.new("World Wind Urban",
    "http://worldwind25.arc.nasa.gov/tile/tile.aspx", 0.8, 9, {:T => "104"}, {:tileSize => OpenLayers::Size.new(512,512)})
  WORLDWIND_BATHY = Layer::WorldWind.new("World Wind Bathymetry",
    "http://worldwind25.arc.nasa.gov/tile/tile.aspx", 36, 4, {:T => "bmng.topo.bathy.200406"}, {:tileSize => OpenLayers::Size.new(512,512)})


  class Map
    include JsWrapper
        
    def initialize(map, options = {}, &block)
      @container = map
      @variable = map
      @options = {:theme => false}.merge(options)
      @js = JsGenerator.new
      yield(self, @js) if block_given?
    end

    #Outputs in JavaScript the creation of a OpenLayers.Map object 
    def create
      "new OpenLayers.Map('#{@container}', #{JsWrapper::javascriptify_variable(@options)})"
    end
    
    #Outputs the initialization code for the map
    def to_html(options = {})
      no_script_tag = options[:no_script_tag]
      no_declare = options[:no_declare]
      no_global = options[:no_global]
        
      html = ""
      html << "<script defer=\"defer\" type=\"text/javascript\">\n" if !no_script_tag
      #put the functions in a separate javascript file to be included in the page
      html << "var #{@variable};\n" if !no_declare and !no_global

      if !no_declare and no_global 
        html << "#{declare(@variable)}\n"
      else
        html << "#{assign_to(@variable)}\n"
      end
      html << @js.to_s
      html << "</script>\n" if !no_script_tag
        
      html
    end
  end
  
end
