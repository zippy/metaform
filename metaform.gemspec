# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'metaform/version'

Gem::Specification.new do |gem|
  gem.name          = "metaform"
  gem.version       = Metaform::VERSION
  gem.authors       = ["Eric Harris-Braun"]
  gem.email         = ["eric@harris-braun.com"]
  gem.description   = %q{A rails engine with a domain specific language for creating complex forms with separate data, presentation and workflow abstractions.}
  gem.summary       = %q{MetaForm provides a robust framework for creating large and complex dataforms.  It includes a DSL for declaring data types and relations and separately presentation of that data, as well as form workflows.  MetaForm renders forms based on the DSL and an a number of widget types for most of the standard interactions you might have on forms.}
  gem.homepage      = "https://github.com/zippy/metaform"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rspec-rails"
  gem.add_dependency "rails"         , "~> 3.2"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
