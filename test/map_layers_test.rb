$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'map_layers'
require 'js_classes'
require 'map'
require 'view_helpers'

require 'test/unit'

class MapLayersTest < Test::Unit::TestCase
  
  include MapLayers
  
  def test_google_example
    @map = MapLayers::Map.new("map_div")
    @map << @map.add_map_layer(:Google, "Google Streets")
    @map << @map.zoom_to_max_extent()
    html =<<EOS
<script defer="defer" type="text/javascript">
var map;
map = new OpenLayers.Map('map_div', {theme : false});
map.addLayer(new OpenLayers.Layer.Google("Google Streets"));
map.zoomToMaxExtent();
</script>
EOS
    assert_equal(html , @map.to_html)
  end

  def test_wms_example
    #var map = new OpenLayers.Map('map', {theme: false});
    #map.addControl( new OpenLayers.Control.LayerSwitcher() );
    #var wms = new OpenLayers.Layer.WMS( "OpenLayers WMS", 
    #  "http://labs.metacarta.com/wms/vmap0", {layers: 'basic'} );
    #map.addLayer(wms);
    #map.zoomToMaxExtent();
    @map = MapLayers::Map.new("map_div")
    @map << @map.add_control(Control::LayerSwitcher.new)
    @map << @map.add_map_layer(:WMS, "OpenLayers WMS", "http://labs.metacarta.com/wms/vmap0", {:layers => 'basic'} )
    @map << @map.zoom_to_max_extent()
    html =<<EOS
<script defer="defer" type="text/javascript">
var map;
map = new OpenLayers.Map('map_div', {theme : false});
map.addControl(new OpenLayers.Control.LayerSwitcher());
map.addLayer(new OpenLayers.Layer.WMS("OpenLayers WMS","http://labs.metacarta.com/wms/vmap0",{layers : "basic"}));
map.zoomToMaxExtent();
</script>
EOS
    assert_equal(html , @map.to_html)
  end
  
  def test_kml_example
    @map = MapLayers::Map.new("map_div")
    #map.addLayer(new OpenLayers.Layer.GML("KML", "/places/kml", {format: OpenLayers.Format.KML}));
    @map << @map.add_new_layer(:GML, "KML", "/places/kml", {:format=> "OpenLayers.Format.KML"})
    html =<<EOS
<script defer="defer" type="text/javascript">
var map;
map = new OpenLayers.Map('map_div', {theme : false});
map.addNewLayer(GML,"KML","/places/kml",{format : "OpenLayers.Format.KML"});
</script>
EOS
    assert_equal(html , @map.to_html)
  end
  
  def test_wfs_example
    @map = MapLayers::Map.new("map_div")
    #var wfs = new OpenLayers.Layer.WFS( "WFS",
    #        "/places/wfs?",
    #        {typename: "places", maxfeatures: 50},
    #        { featureClass: OpenLayers.Feature.WFS});
    #map.addLayer(wfs);
    @map << @map.add_map_layer(:WFS, "WFS", "/places/wfs?", {:typename => "places", :maxfeatures => 50}, {:featureClass => "OpenLayers.Feature.WFS"})
    html =<<EOS
<script defer="defer" type="text/javascript">
var map;
map = new OpenLayers.Map('map_div', {theme : false});
map.addLayer(new OpenLayers.Layer.WFS("WFS","/places/wfs?",{typename : "places",maxfeatures : 50},{featureClass : "OpenLayers.Feature.WFS"}));
</script>
EOS
    assert_equal(html , @map.to_html)
  end

end
