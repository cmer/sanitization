# Sanitization

Sanitization makes it easy to store slightly cleaner strings to your database.

![Specs](https://github.com/cmer/sanitization/actions/workflows/specs.yml/badge.svg)
[![Gem Version](https://badge.fury.io/rb/sanitization.svg)](https://badge.fury.io/rb/sanitization)

### Features (all optional):

- White space stripping
- White space collapsing (multiple consecutive spaces combined into one)
- Empty string to nil (if database column supports it)
- Change casing (ie. upcase, downcase, titlecase, etc)


### Defaults

By default, Sanitization has all options disabled. It is recommended you use a configuration block to set
sensitive defaults for your projects.

For example, I use:

```ruby
# config/initializers/sanitization.rb

Sanitization.configure do |config|
  config.strip = true
  config.collapse = true
  config.nullify = true
end

# or you can use the following shortcut instead:

Sanitization.simple_defaults!
```


### Configuration Options

- Strip leading & training white spaces (`strip: true|false`)
- Collapse consecutive spaces (`collapse: true|false`)
- Store empty strings as `null` if the database column allows it (`nullify: true|false`)
- All String columns are sanitized (`only: nil, except: nil`)
- Also sanitize strings of type `text` (`include_text_type: true|false`)
- Change casing: (`case: :none|:up|:down|:custom`)


## Installation

```sh
bundle add sanitization
```


## Usage

```ruby

# Assuming the following configuration block:
Sanitization.configure do |config|
  config.strip = true
  config.collapse = true
  config.nullify = true
end

# Default settings for all strings
class Person < ApplicationModel
  sanitizes
  # is equivalent to:
  sanitizes strip: true, collapse: true, include_text_type: false
end

# Default settings for all strings, except a specific column
class Person < ApplicationModel
  sanitizes except: :alias
end

# Default settings + titlecase for specific columns
class Person < ApplicationModel
  sanitizes only: [:first_name, :last_name], case: :title
end

# Complex example. All these lines could be used in combination.
class Person
  # Apply default settings and `titlecase` to all string columns, except `description`.
  sanitizes case: :title, except: :description

  # Keep previous settings, but specify `upcase` for 2 columns.
  sanitizes only: [:first_name, :last_name], case: :up

  # Keep previous settings, but specify `downcase` for a single column.
  sanitizes only: :email, case: :downcase

  # Apply default settings to column `description`, of type `text`. By default, `text` type is NOT sanitized.
  sanitizes only: :description, include_text_type: true

  # Disable collapsing for `do_not_collapse`.
  sanitizes only: :do_not_collapse, collapse: false

  # Sanitize with a custom casing method named `leetcase` for the `133t` column.
  # Don't nullify empty strings.
  sanitizes only: '1337', case: :leet, nullify: false
end

```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
