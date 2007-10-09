################################################################################
class MetaformGenerator < Rails::Generator::Base

  ################################################################################
  def manifest
    @migrations = []

    Dir.foreach(File.dirname(__FILE__) + '/templates') do |file|
      next unless file.match(/^\d+_/)
      @migrations << file
    end

    record do |m|
      m.directory('forms')
#      m.file('sessions_new.rhtml', 'app/views/sessions/new.rhtml')

      @migrations.sort.each do |f|
        m.migration_template(f, 'db/migrate', {
          :assigns => {:migration_name => f.sub(/^\d+_/, '').camelize}, 
          :migration_file_name => f.sub(/^\d+_/, '').sub(/\.rb$/, ''),
        })
      end
    end
  end

end
################################################################################
