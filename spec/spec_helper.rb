require "bundler/setup"
require "sanitization"
require "byebug"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define(version: 1) do
  create_table :people do |t|
    t.string :first_name, null: false
    t.string :last_name, null: false
    t.string :company
    t.string :address
    t.string :city, null: false
    t.string :title
    t.string :email, null: false
    t.text   :description
    t.text   :education
    t.string :do_not_collapse, null: false
    t.date   :dob
    t.integer :age
    t.string '1337'
  end
end
