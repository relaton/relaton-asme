# frozen_string_literal: true

require_relative "lib/relaton_asme/version"

Gem::Specification.new do |spec|
  spec.name = "relaton-asme"
  spec.version = RelatonAsme::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Fetch and parse ASME standards and codes"
  spec.description = "Retrieve bibliographic information of ASME standards and codes."
  spec.homepage = "https://github.com/relaton/relaton-asme"
  spec.license = "BSD-2-Clause"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob(%w[lib/**/* README.adoc CHANGELOG.md LICENSE])
  spec.require_paths = ["lib"]

  spec.add_dependency "lutaml-model", "~> 0.7"
  spec.add_dependency "mechanize"
end
