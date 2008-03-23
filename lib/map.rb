require 'js_wrapper'
  
module MapLayers

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
    
    #Add a new layer. Defined values of +type+ are: .........
    def add_map_layer(type, *args)
      args.collect! { |arg| JsWrapper.javascriptify_variable(arg) }
      JsExpr.new("#{@variable}.addLayer(new OpenLayers.Layer.#{type}(#{args.join(",")}))")
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
