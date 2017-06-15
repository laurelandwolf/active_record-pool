require "pry"
require "rspec"
require "with_model"
require "active_record-pool"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

RSpec.configure do |let|

  # Exit the spec after the first failure
  let.fail_fast = true

  # Only run a specific file, using the ENV variable
  # Example: FILE=spec/write/version_spec.rb bundle exec rake spec
  let.pattern = ENV["FILE"]

  # Show the slowest examples in the suite
  let.profile_examples = true

  # Colorize the output
  let.color = true

  # Output as a document string
  let.default_formatter = "doc"

  let.extend WithModel
end
