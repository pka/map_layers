# Workaround a problem with script/plugin and http-based repos.
# See http://dev.rubyonrails.org/ticket/8189
Dir.chdir(Dir.getwd.sub(/vendor.*/, '')) do

def copy_files(source_path, destination_path, plugin_root)
  source, destination = File.join(File.expand_path(plugin_root), source_path), File.join(RAILS_ROOT, destination_path)
  FileUtils.mkdir(destination) unless File.exist?(destination)
  FileUtils.cp_r(source, destination)
end

copy_files("/public/.", "/public", File.dirname(__FILE__))

end
