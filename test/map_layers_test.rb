$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'map_layers'
require 'js_wrapper'
require 'js_classes'
require 'map'
require 'view_helpers'

require 'test/unit'

class MapLayersTest < Test::Unit::TestCase
  
  include MapLayers
  
  def test_javascriptify_method
    assert_equal("addOverlayToHello",JsWrapper::javascriptify_method("add_overlay_to_hello"))
  end

  def test_javascriptify_variable_mapping_object
    map = Map.new("div")
    assert_equal(map.to_javascript,JsWrapper::javascriptify_variable(map))
  end

  def test_javascriptify_variable_numeric
    assert_equal("123.4",JsWrapper::javascriptify_variable(123.4))
  end

  def test_javascriptify_variable_array
    map = Map.new("div")
    assert_equal("[123.4,#{map.to_javascript},[123.4,#{map.to_javascript}]]",JsWrapper::javascriptify_variable([123.4,map,[123.4,map]]))
  end

  def test_javascriptify_variable_hash
    map = Map.new("div")
    test_str = JsWrapper::javascriptify_variable("hello" => map, "chopotopoto" => [123.55,map])
    assert("{hello : #{map.to_javascript},chopotopoto : [123.55,#{map.to_javascript}]}" == test_str || "{chopotopoto : [123.55,#{map.to_javascript}],hello : #{map.to_javascript}}" == test_str)
  end

  def test_method_call_on_mapping_object
    map = Map.new("map")
    assert_equal("map.addHello(123.4)",map.add_hello(123.4).to_s)
  end

  def test_nested_calls_on_mapping_object
    map = Map.new("map")
    assert_equal("map.addHello(map.hoYoYo(123.4),map)",map.add_hello(map.ho_yo_yo(123.4),map).to_s)
  end
  
  def test_declare_variable_latlng
    #point = OpenLayers::LonLat.new([123.4,123.6])
    point = OpenLayers::LonLat.new(123.4,123.6)
    assert_equal("var point = new OpenLayers.LonLat(123.4,123.6);",point.declare("point"))
    assert_equal("point",point.variable)
  end

  def test_array_indexing
    obj = JsVar.new("obj")
    assert_equal("obj[0]",obj[0].variable)
  end

  def test_js_generator
    @map = MapLayers::Map.new("map")
    js = JsGenerator.new
    js.assign("markers", Layer::Markers.new('Markers'))
    @markers = JsVar.new('markers')
    js << @map.addLayer(@markers)
    js.assign("size", OpenLayers::Size.new(10,17))
    js.assign("offset", OpenLayers::Pixel.new(JsExpr.new("-(size.w/2), -size.h")))
    js.assign("icon", OpenLayers::Icon.new('http://boston.openguides.org/markers/AQUA.png',:size,:offset))
    js << @markers.add_marker(OpenLayers::Marker.new(OpenLayers::LonLat.new(0,0),:icon))
    html =<<EOS
markers = new OpenLayers.Layer.Markers("Markers");
map.addLayer(markers);
size = new OpenLayers.Size(10,17);
offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
icon = new OpenLayers.Icon("http://boston.openguides.org/markers/AQUA.png",size,offset);
markers.addMarker(new OpenLayers.Marker(new OpenLayers.LonLat(0,0),icon));
EOS
    assert_equal(html , js.to_s)
  end
  
  def test_google_example
    @map = MapLayers::Map.new("map") do |map, page|
      page << map.add_map_layer(:Google, "Google Streets")
      page << map.zoom_to_max_extent()
    end
    html =<<EOS
<script defer="defer" type="text/javascript">
var map;
map = new OpenLayers.Map('map', {theme : false});
map.addLayer(new OpenLayers.Layer.Google("Google Streets"));
map.zoomToMaxExtent();
</script>
EOS
    assert_equal(html , @map.to_html)
  end

  def test_wms_example
    @map = MapLayers::Map.new("map") do |map,page|
      page << map.add_control(Control::LayerSwitcher.new)
      page << map.add_map_layer(:WMS, "OpenLayers WMS", "http://labs.metacarta.com/wms/vmap0", {:layers => 'basic'} )
      page << map.zoom_to_max_extent()
    end
    html =<<EOS
<script defer="defer" type="text/javascript">
var map;
map = new OpenLayers.Map('map', {theme : false});
map.addControl(new OpenLayers.Control.LayerSwitcher());
map.addLayer(new OpenLayers.Layer.WMS("OpenLayers WMS","http://labs.metacarta.com/wms/vmap0",{layers : "basic"}));
map.zoomToMaxExtent();
</script>
EOS
    assert_equal(html , @map.to_html)
  end
  
  def test_kml_example
    @map = MapLayers::Map.new("map") do |map,page|
      #map.addLayer(new OpenLayers.Layer.GML("KML", "/places/kml", {format: OpenLayers.Format.KML}));
      page << map.add_new_layer(:GML, "KML", "/places/kml", {:format=> "OpenLayers.Format.KML"})
    end
    html =<<EOS
<script defer="defer" type="text/javascript">
var map;
map = new OpenLayers.Map('map', {theme : false});
map.addNewLayer(GML,"KML","/places/kml",{format : "OpenLayers.Format.KML"});
</script>
EOS
    assert_equal(html , @map.to_html)
  end
  
  def test_wfs_example
    @map = MapLayers::Map.new("map_div") do |map, page|
      page << map.add_map_layer(:WFS, "WFS", "/places/wfs?", {:typename => "places"}, {:featureClass => "OpenLayers.Feature.WFS"})
    end
    html =<<EOS
<script defer="defer" type="text/javascript">
var map_div;
map_div = new OpenLayers.Map('map_div', {theme : false});
map_div.addLayer(new OpenLayers.Layer.WFS("WFS","/places/wfs?",{typename : "places"},{featureClass : "OpenLayers.Feature.WFS"}));
</script>
EOS
    assert_equal(html , @map.to_html)
  end

end
