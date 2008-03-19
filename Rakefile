require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the map_layers plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the map_layers plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'MapLayers'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Import new OpenLayers libray. Use SRC=path_to_openlayers'
task :import_ol do
  FileUtils.rm_r(File.join(File.dirname(__FILE__), "OpenLayers"))
  copy_files("/lib", "/OpenLayers", ENV['SRC'])
  copy_files("/tools", "/OpenLayers", ENV['SRC'])
  copy_files("/build", "/OpenLayers", ENV['SRC'])
  FileUtils.rm_r(File.join(File.dirname(__FILE__), "public"))
  copy_files("/OpenLayers.js", "/public/javascripts", ENV['SRC'])
  copy_files("/img/.", "/public/images/OpenLayers", ENV['SRC'])
  copy_files("/theme/default/img/.", "/public/images/OpenLayers", ENV['SRC'])
  FileUtils.mkdir_p(File.join(File.dirname(__FILE__), "/public/stylesheets"))
  system("ruby -pe 'gsub(/img\\//, \"/images/OpenLayers/\")' <#{ENV['SRC']}/theme/default/style.css >#{File.dirname(__FILE__)}/public/stylesheets/map.css")
end

def copy_files(source_path, destination_path, olpath)
  source, destination = File.join(olpath, source_path), File.join(File.dirname(__FILE__), destination_path)
  FileUtils.mkdir_p(destination) unless File.exist?(destination)
  FileUtils.cp_r(source, destination)
end
