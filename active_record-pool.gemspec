#!/usr/bin/env ruby

lib = File.expand_path(File.join("..", "lib"), __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_record/pool/version"

Gem::Specification.new do |spec|
  spec.name = "active_record-pool"
  spec.version = ActiveRecord::Pool::VERSION
  spec.authors = ["Kurtis Rainbolt-Greene"]
  spec.email = ["kurtis@laurelandwolf.com"]
  spec.summary = %q{active_record-pool is an extension to active_record that gives you an interface to write high-speed inserts, updates, & delete in a manageable way.}
  spec.description = spec.summary
  spec.homepage = "http://laurelandwolf.github.io/active_record-pool"
  spec.license = "MIT"

  spec.files = Dir[File.join("lib", "**", "*")]
  spec.executables = Dir[File.join("bin", "**", "*")].map! { |f| f.gsub(/bin\//, "") }
  spec.test_files = Dir[File.join("test", "**", "*"), File.join("spec", "**", "*")]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", "~> 5.0"
  spec.add_development_dependency "with_model", "~> 2.0"
  spec.add_development_dependency "sqlite3", "~> 1.1"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 10.1"
  spec.add_development_dependency "pry", "~> 0.9"
  spec.add_development_dependency "pry-doc", "~> 0.6"
end
