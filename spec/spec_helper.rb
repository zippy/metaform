require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
require 'fileutils'

plugin_spec_dir = File.dirname(__FILE__)
ActiveRecord::Base.logger = Logger.new(plugin_spec_dir + "/debug.log")

databases = YAML::load(IO.read(plugin_spec_dir + "/db/database.yml"))
# remove existing database (no way to create transactions for the plugin?)
db = databases[ENV["DB"] || "sqlite3"]
begin
  FileUtils.rm plugin_spec_dir + "/db/#{db[:dbfile]}" if File.exist?
rescue
end
ActiveRecord::Base.establish_connection(db)
load(File.join(plugin_spec_dir, "db", "schema.rb"))

forms_dir = plugin_spec_dir+"/resources/forms"
Dir.foreach(forms_dir) do |file|
  require File.join(forms_dir, file) if file.match(/\.rb$/)
end
