# frozen_string_literal: true

require_relative "lib/jekyll-databuilder/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-databuilder"
  spec.version       = Jekyll::Databuilder::VERSION
  spec.authors       = ["Brett Gneiting"]
  spec.email         = ["bgneiting@mediweb.jp"]
  spec.summary       = "."
  spec.description   = "."
  spec.homepage      = "https://github.com/TokyoBits/jekyll-databuilder"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").grep(%r!^lib/!)
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4.0"

  spec.add_dependency "jekyll", ">= 3.7", "< 5.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 12.0"
end
