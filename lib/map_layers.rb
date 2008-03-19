module MapLayers # :nodoc:
  # extend the class that include this with the methods in ClassMethods
  def self.included(base)
    base.extend(ClassMethods)
  end

  def map_layers_config
    self.class.map_layers_config
  end

  module ClassMethods

    def map_layer(model_id = nil, options = {})
      options.assert_valid_keys(:id, :lat, :lon, :geom, :text)

      # converts Foo::BarController to 'bar' and FooBarsController to 'foo_bar' and AddressController to 'address'
      model_id = self.to_s.split('::').last.sub(/Controller$/, '').pluralize.singularize.underscore unless model_id

      # create the configuration
      @map_layers_config = MapLayers::Config::new(model_id, options)

      module_eval do
        include MapLayers::KML
        include MapLayers::WFS
        include MapLayers::GeoRSS
        include MapLayers::Rest
      end

    end

    def map_layers_config
      @map_layers_config || self.superclass.instance_variable_get('@map_layers_config')
    end
  
  end


  class Config
    attr_reader :model_id, :id, :lat, :lon, :geom, :text
    
    def initialize(model_id, options)
      @model_id = model_id.to_s.pluralize.singularize
      @id = options[:id] || :id
      @lat = options[:lat] || :lat
      @lon = options[:lon] || :lng
      @geom = options[:geom]
      @text = options[:text] || :name
    end
    
    def model
      @model ||= @model_id.to_s.camelize.constantize
    end
  end

  
  class Feature < Struct.new(:text, :x, :y, :id)
    attr_accessor :geom
    def self.from_geom(text, geom, id = nil)
      f = new(text, geom.x, geom.y, id)
      f.geom = geom
      f
    end
  end

  # KML Server methods
  module KML
    
    # Publish layer in KML format
    def kml
      rows = map_layers_config.model.find(:all, :limit => KML_FEATURE_LIMIT)
      @features = rows.collect do |row|
        if map_layers_config.geom
          Feature.from_geom(row.attributes[map_layers_config.text.to_s], row.attributes[map_layers_config.geom.to_s])
        else
          Feature.new(row.attributes[map_layers_config.text.to_s], row.attributes[map_layers_config.lon.to_s], row.attributes[map_layers_config.lat.to_s])
        end
      end
      @folder_name = map_layers_config.model_id.to_s.pluralize.humanize
      render :inline => KML_XML_ERB, :content_type => "text/xml"
    rescue
      render :text => KML_EMPTY_RESPONSE, :content_type => "text/xml"
    end
    
    private

    KML_FEATURE_LIMIT = 1000
    
    KML_XML_ERB = <<EOS # :nodoc:
<?xml version="1.0" encoding="utf-8" ?>
<kml xmlns="http://earth.google.com/kml/2.0">
  <Document>
  <Folder><name><%= @folder_name %></name>
  <% for feature in @features -%>
    <Placemark>
      <description><%= feature.text %></description>
      <Point><coordinates><%= feature.x %>,<%= feature.y %></coordinates></Point>
    </Placemark>
  <% end -%>
  </Folder>
  </Document>
</kml>
EOS

    KML_EMPTY_RESPONSE = <<EOS # :nodoc:
<?xml version="1.0" encoding="utf-8" ?>
<kml xmlns="http://earth.google.com/kml/2.0">
  <Document>
  </Document>
</kml>
EOS
    
  end
  
  # WFS Server methods
  module WFS
    
    # Publish layer in WFS format
    def wfs
      minx, miny, maxx, maxy = extract_params
      if map_layers_config.geom
        spatial_cond = if map_layers_config.model.respond_to?(:sanitize_sql_hash_for_conditions)
          map_layers_config.model.sanitize_sql_hash_for_conditions(map_layers_config.geom => [[minx, miny],[maxx, maxy]])
        else # Rails < 2
          map_layers_config.model.sanitize_sql_hash(map_layers_config.geom => [[minx, miny],[maxx, maxy]])
        end
        rows = map_layers_config.model.find(:all, :limit => @maxfeatures, :conditions => spatial_cond)
        @features = rows.collect do |row|
          Feature.from_geom(row.attributes[map_layers_config.text.to_s], row.attributes[map_layers_config.geom.to_s])
        end
      else
        rows = map_layers_config.model.find(:all, :limit => @maxfeatures)
        @features = rows.collect do |row|
          Feature.new(row.attributes[map_layers_config.text.to_s], row.attributes[map_layers_config.lon.to_s], row.attributes[map_layers_config.lat.to_s])
        end
      end
      render :inline => WFS_XML_ERB, :content_type => "text/xml"
    rescue
      render :text => WFS_EMPTY_RESPONSE, :content_type => "text/xml"
    end
    
    private

    WFS_FEATURE_LIMIT = 1000
    
    def extract_params # :nodoc:
      @maxfeatures = (params[:maxfeatures] || WFS_FEATURE_LIMIT).to_i
      req_bbox = params['BBOX'].split(/,/).collect {|n| n.to_f } rescue nil
      @bbox = req_bbox || [-180.0, -90.0, 180.0, 90.0]
    end

    WFS_XML_ERB = <<EOS # :nodoc:
<?xml version='1.0' encoding="UTF-8" ?>
<wfs:FeatureCollection
   xmlns:ms="http://mapserver.gis.umn.edu/mapserver"
   xmlns:wfs="http://www.opengis.net/wfs"
   xmlns:gml="http://www.opengis.net/gml"
   xmlns:ogc="http://www.opengis.net/ogc"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://www.opengis.net/wfs http://schemas.opengeospatial.net/wfs/1.0.0/WFS-basic.xsd 
                       http://mapserver.gis.umn.edu/mapserver http://www.geopole.org/map/wfs?SERVICE=WFS&amp;VERSION=1.0.0&amp;REQUEST=DescribeFeatureType&amp;TYPENAME=geopole&amp;OUTPUTFORMAT=XMLSCHEMA">
  <gml:boundedBy>
    <gml:Box srsName="EPSG:4326">
      <gml:coordinates><%= @bbox[0] %>,<%= @bbox[1] %> <%= @bbox[2] %>,<%= @bbox[3] %></gml:coordinates>
    </gml:Box>
  </gml:boundedBy>
  <% for feature in @features -%>
    <gml:featureMember>
      <ms:geopole>
        <gml:boundedBy>
          <gml:Box srsName="EPSG:4326">
            <gml:coordinates><%= feature.x %>,<%= feature.y %> <%= feature.x %>,<%= feature.y %></gml:coordinates>
          </gml:Box>
        </gml:boundedBy>
        <ms:msGeometry>
        <gml:Point srsName="EPSG:4326">
          <gml:coordinates><%= feature.x %>,<%= feature.y %></gml:coordinates>
        </gml:Point>
        </ms:msGeometry>
        <ms:text><%= feature.text %></ms:text>
      </ms:geopole>
    </gml:featureMember>
  <% end -%>
</wfs:FeatureCollection>
EOS

    WFS_EMPTY_RESPONSE = <<EOS # :nodoc:
<?xml version='1.0' encoding="ISO-8859-1" ?>
<wfs:FeatureCollection
   xmlns:wfs="http://www.opengis.net/wfs"
   xmlns:gml="http://www.opengis.net/gml"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://www.opengis.net/wfs http://schemas.opengeospatial.net/wfs/1.0.0/WFS-basic.xsd">
   <gml:boundedBy>
      <gml:null>missing</gml:null>
   </gml:boundedBy>
</wfs:FeatureCollection>
EOS
    
  end

  # GeoRSS Server methods
  # http://www.georss.org/1
  
  module GeoRSS
    
    # Publish layer in GeoRSS format
    def georss
      rows = map_layers_config.model.find(:all, :limit => GEORSS_FEATURE_LIMIT)
      @features = rows.collect do |row|
        if map_layers_config.geom
          Feature.from_geom(row.attributes[map_layers_config.text.to_s], row.attributes[map_layers_config.geom.to_s], row.attributes[map_layers_config.id.to_s])
        else
          Feature.new(row.attributes[map_layers_config.text.to_s], row.attributes[map_layers_config.lon.to_s], row.attributes[map_layers_config.lat.to_s], row.attributes[map_layers_config.id.to_s])
        end
      end
      @base_url = "http://#{request.env["HTTP_HOST"]}/"
      @item_url = "#{@base_url}#{map_layers_config.model_id.to_s.pluralize}"
      @title = map_layers_config.model_id.to_s.pluralize.humanize
      render :inline => GEORSS_XML_ERB, :content_type => "text/xml"
    rescue
      render :text => GEORSS_EMPTY_RESPONSE, :content_type => "text/xml"
    end
    
    private

    GEORSS_FEATURE_LIMIT = 1000
    
    GEORSS_XML_ERB = <<EOS # :nodoc:
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns="http://purl.org/rss/1.0/"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:georss="http://www.georss.org/georss">
<docs>This is an RSS file.  Copy the URL into your aggregator of choice.  If you don't know what this means and want to learn more, please see: <span>http://platial.typepad.com/news/2006/04/really_simple_t.html</span> for more info.</docs>
<channel rdf:about="<%= @base_url %>">
<link><%= @base_url %></link>
<title><%= @title %></title>
<description></description>
<items>
<rdf:Seq>
<% for feature in @features -%>
<rdf:li resource="<%= @item_url %>/<%= feature.id %>"/>
<% end -%>
</rdf:Seq>
</items>
</channel>
<% ts=Time.now.rfc2822 -%>
<% for feature in @features -%>
<item rdf:about="<%= @item_url %>/<%= feature.id %>">
<!--<link><%= @item_url %>/<%= feature.id %></link>-->
<title><%= @title %></title>
<description><![CDATA[<%= feature.text %>]]></description>
<georss:point><%= feature.y %> <%= feature.x %></georss:point>
<dc:creator>map-layers</dc:creator>
<dc:date><%= ts %></dc:date>
</item>
<% end -%>
</rdf:RDF>
EOS

    GEORSS_EMPTY_RESPONSE = <<EOS # :nodoc:
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns="http://purl.org/rss/1.0/"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:georss="http://www.georss.org/georss">
<docs>Empty Result</docs>
<link><%= @base_url %></link>
<title><%= @title %></title>
<description></description>
<channel rdf:about="<%= @base_url %>">
<link><%= @base_url %></link>
<title><%= @title %></title>
<description></description>
<items>
<rdf:Seq>
</rdf:Seq>
</items>
</channel>
</rdf:RDF>
EOS
    
  end
  
  # Restful feture Server methods (http://featureserver.org/)
  module Rest
    
    def index
      respond_to do |format|
        format.xml { wfs }
        format.kml { kml }
      end
    end
    
  end
  
end