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
      m.file('metaform.js', 'public/javascripts/metaform.js')
      m.file('metaform.css', 'public/stylesheets/metaform.css')
      m.directory('app/views/records')
      m.file('records_new.rhtml', 'app/views/records/new.rhtml')
      m.file('records_show.rhtml', 'app/views/records/show.rhtml')

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
