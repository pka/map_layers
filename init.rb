require 'map_layers'
require 'js_classes'
require 'map'
require 'view_helpers'

ActionController::Base.send(:include, MapLayers)
ActionView::Base.send(:include, MapLayers::ViewHelpers)

Mime::Type.register "application/vnd.google-earth.kml+xml", :kml
