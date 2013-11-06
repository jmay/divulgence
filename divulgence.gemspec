# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'divulgence/version'

Gem::Specification.new do |gem|
  gem.name          = "divulgence"
  gem.version       = Divulgence::VERSION
  gem.authors       = ["Jason W. May"]
  gem.email         = ["jmay@pobox.com"]
  gem.description   = %q{Sharing stuff}
  gem.summary       = %q{Sharing stuff}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'rest-client' # for talking to registry and other nodes
  # gem.add_dependency 'treet'

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "webmock"
end
