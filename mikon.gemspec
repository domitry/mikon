# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mikon/version'

Gem::Specification.new do |spec|
  spec.name          = "mikon"
  spec.version       = Mikon::VERSION
  spec.authors       = ["Naoki Nishida"]
  spec.email         = ["domitry@gmail.com"]
  spec.summary       = %q{DataFrame library for Ruby}
  spec.description   = %q{DataFrame works with NMatrix, Statsample, and Nyaplot}
  spec.homepage      = "http://github.com/domitry/mikon"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "nmatrix", "~> 0.1.0.rc5"
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
