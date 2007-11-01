namespace(:test) do
  Rake::TestTask.new(:metaform => :test) do |t|
    t.libs << "test"
    t.pattern = "vendor/plugins/metaform/test/**/*_test.rb"
    t.verbose = true
  end
  Rake::Task['test:metaform'].comment = "Run the metaform plugin tests"
end
