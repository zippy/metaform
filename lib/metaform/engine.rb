module Metaform
  mattr_accessor :usingPostgres,:ilike

  def self.set_ilike
    self.ilike = usingPostgres ? 'ilike' : 'like'
  end
  def self.set_usingPostgres(val)
    self.usingPostgres = val
    set_ilike
  end

  self.set_usingPostgres(true)
  
  class Engine < Rails::Engine
    initializer "setup database" do |app|
      Metaform.set_usingPostgres(ActiveRecord::Base.connection.class.to_s == 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter')
    end
    initializer "setup metaform including loading the forms" do |app|

      ActionView::Base.send :include, MetaformHelperMethods
      
      fd = app.root.join(Form.forms_dir)
      if File.directory?(fd)
        forms = []
        requires = []
        Dir.foreach(fd) do |file|
          if file =~ /(.*)\.rb$/
            if file =~ /(.*)form\.rb$/i
              forms << $1
            else
              requires << file
            end
          end
        end
        requires.each do |file|
          require fd.join(file)
        end
        forms.each do |klass|
          file = fd.join(klass+'form.rb').to_s
          file_contents = IO.read(file)
          new_class = <<-EORUBY
          class ::#{klass} < Form
            def setup
              #{file_contents}
            end
            def getBinding
              binding
            end
          end
          EORUBY
          eval new_class,nil,file
        end
      end
    end
  end
end
