require 'js_wrapper'
  
module MapLayers

  class Map
    include JsWrapper
    
    def initialize(div, options = {})
      @container = div
      @variable = "map"
      @options = {:theme => false}.merge(options)
      @init = []
      @init_end = [] #for stuff that must be initialized at the end (controls)
      @init_begin = [] #for stuff that must be initialized at the beginning (center + zoom)
      @global_init = []
    end

    #Outputs in JavaScript the creation of a OpenLayers.Map object 
    def create
      "new OpenLayers.Map('#{@container}', #{JsWrapper::javascriptify_variable(@options)})"
    end
    
    def <<(arg)
      @init << arg
    end
    
    def add_map_layer(type, *args)
      args.collect! { |arg| JsWrapper.javascriptify_variable(arg) }
      "#{@variable}.addLayer(new OpenLayers.Layer.#{type}(#{args.join(",")}));"
    end
    
    #Outputs the initialization code for the map. By default, it outputs the script tags, performs the initialization in response to the onload event of the window and makes the map globally available. If you pass +true+ to the option key <tt>:full</tt>, the map will be setup in full screen, in which case it is not necessary (but not harmful) to set a size for the map div.
    def to_html(options = {})
      no_script_tag = options[:no_script_tag]
      no_declare = options[:no_declare]
      no_global = options[:no_global]
      load_pr = options[:proto_load] #to prevent some problems when the onload event callback from Prototype is used
        
      html = ""
      html << "<script defer=\"defer\" type=\"text/javascript\">\n" if !no_script_tag
      #put the functions in a separate javascript file to be included in the page
      html << @global_init * "\n"
      html << "var #{@variable};\n" if !no_declare and !no_global

      if !no_declare and no_global 
        html << "#{declare(@variable)}\n"
      else
        html << "#{assign_to(@variable)}\n"
      end
      html << @init_begin * "\n"
      html << @init * "\n"
      html << @init_end * "\n"
      html << "\n</script>\n" if !no_script_tag
        
      html
    end
  end
  
end
