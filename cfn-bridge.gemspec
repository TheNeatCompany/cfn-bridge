# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloud_formation/bridge/version'

Gem::Specification.new do |spec|
  spec.name          = "cfn-bridge"
  spec.version       = CloudFormation::Bridge::VERSION
  spec.authors       = ["Maurício Linhares"]
  spec.email         = ["mlinhares@neat.com"]
  spec.summary       = %q{Implements custom operations for CF calls}
  spec.description   = %q{Implements custom operations for CF calls}
  spec.homepage      = "https://github.com/TheNeatCompany/cfn-bridge"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.6.5'
  spec.add_development_dependency 'rake', '~> 10.3.2'
  spec.add_development_dependency 'rspec', '~> 3.0.0'
  spec.add_development_dependency 'dotenv', '~> 0.11.1'
  spec.add_development_dependency 'pry', '~> 0.10.0'

  spec.add_dependency 'aws-sdk', '~> 1.50.0'
  spec.add_dependency 'faraday', '~> 0.9.0'
  spec.add_dependency 'faraday_middleware', '~> 0.9.1'
  spec.add_dependency 'thor', '~> 0.19.1'
  spec.add_dependency 'typhoeus', '~> 0.6.9'
  spec.add_dependency 'rollbar', '~> 1.0.0'
end
