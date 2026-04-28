# Sanitization

Strip, collapse, nullify, and case-fix string attributes in ActiveRecord models without writing a `normalizes` lambda for every column.

![Specs](https://github.com/cmer/sanitization/actions/workflows/specs.yml/badge.svg)
[![Gem Version](https://badge.fury.io/rb/sanitization.svg)](https://badge.fury.io/rb/sanitization)

## What it does

Sanitization keeps the strings you store in your database clean, without sprinkling normalization rules across every model. It can:

- Strip leading and trailing whitespace (including unicode invisible characters)
- Collapse runs of consecutive spaces into a single space
- Convert empty strings to `nil` (when the column allows null)
- Apply case transformations (`:up`, `:down`, `:title`, or any custom `*case` method)

You declare your intent once, at the model level, and Sanitization figures out which columns to touch by introspecting the schema.

## Why not just use `normalizes`?

As of Rails 7.1, ActiveRecord ships [`normalizes`](https://api.rubyonrails.org/classes/ActiveRecord/Normalization/ClassMethods.html), which Sanitization is now built on top of (since 2.0). So why use this gem?

Because `normalizes` is a low-level primitive. It normalizes **one attribute at a time**, with **one lambda at a time**, and has **no notion of project-wide defaults**. In a real app with dozens of models and hundreds of string columns, that gets verbose fast.

Compare a typical model with manual `normalizes`:

```ruby
class Person < ApplicationRecord
  normalizes :first_name, :last_name, :email, :phone, :address, :city,
             with: ->(v) {
               v = v.strip.squeeze(" ")
               v.empty? ? nil : v
             }
  normalizes :email, with: ->(v) { v&.downcase }
  normalizes :first_name, :last_name, with: ->(v) { v&.titlecase }
  # ...and you have to remember to add every new string column here, forever
end
```

Versus the same thing with Sanitization:

```ruby
class Person < ApplicationRecord
  sanitizes                                            # strip + collapse + nullify on every string column
  sanitizes only: :email, case: :down
  sanitizes only: [:first_name, :last_name], case: :title
end
```

The wins:

- **Sane defaults, set once.** Configure `strip`, `collapse`, `nullify`, and `case` globally in an initializer and every model picks them up. No per-column boilerplate.
- **Schema-aware.** `sanitizes` (with no arguments) automatically applies to every `string` column on the table. Add a new column, it's covered. No code changes required.
- **Composable rules.** Stack multiple `sanitizes` calls to start from defaults and refine specific columns (`only:`, `except:`, per-column `case:`, etc.) without duplicating the base logic.
- **Smart `nullify`.** Empty strings only become `nil` when the column is actually nullable, by inspecting `null` on the column definition. You don't have to remember which columns are `NOT NULL`.
- **Multibyte-safe whitespace handling.** Strips Unicode invisibles (zero-width space, BOM, word joiner, etc.) — the kind of garbage that shows up when users paste from Word or chat apps.

Under the hood, every option you pass is compiled into a single `normalizes` lambda per column, so you keep all the upstream behavior (assignment-time normalization, `where`/`find_by` lookup normalization, `record.normalize_attribute(:col)`, etc.) — you just don't have to write it.

## Setting sane defaults

Out of the box, Sanitization does nothing — every option is opt-in. The recommended setup is to enable the common-sense defaults in an initializer:

```ruby
# config/initializers/sanitization.rb

Sanitization.configure do |config|
  config.strip = true
  config.collapse = true
  config.nullify = true
end

# or, equivalently:
Sanitization.simple_defaults!
```

With that in place, calling `sanitizes` in any model strips, collapses, and nullifies every string column with no further configuration. Models can still override any option locally.

## Installation

```sh
bundle add sanitization
```

Compatibility: Ruby >= 3.2, Rails >= 7.1.

## Usage

```ruby
# Assuming the initializer above is loaded.

# Apply default settings to every string column.
class Person < ApplicationRecord
  sanitizes
  # equivalent to: sanitizes strip: true, collapse: true, nullify: true, include_text_type: false
end

# Apply defaults to every string column except one.
class Person < ApplicationRecord
  sanitizes except: :alias
end

# Apply defaults, plus titlecase on specific columns.
class Person < ApplicationRecord
  sanitizes only: [:first_name, :last_name], case: :title
end

# Stack multiple calls to refine behavior per column.
class Person < ApplicationRecord
  # Defaults + titlecase for every string column except `description`.
  sanitizes case: :title, except: :description

  # Override case for two columns.
  sanitizes only: [:first_name, :last_name], case: :up

  # Override case for a single column.
  sanitizes only: :email, case: :downcase

  # Include a `text` column (text columns are skipped by default).
  sanitizes only: :description, include_text_type: true

  # Disable collapsing for one column.
  sanitizes only: :do_not_collapse, collapse: false

  # Use a custom `*case` method (e.g. a String#leetcase you defined),
  # and don't nullify empty strings on this column.
  sanitizes only: :handle, case: :leet, nullify: false
end
```

## Configuration options

| Option              | Values                                | Description                                                                 |
| ------------------- | ------------------------------------- | --------------------------------------------------------------------------- |
| `strip`             | `true` / `false`                      | Strip leading and trailing whitespace (including Unicode invisibles).       |
| `collapse`          | `true` / `false`                      | Collapse runs of consecutive whitespace into a single space.                |
| `nullify`           | `true` / `false`                      | Convert empty strings to `nil` when the column allows null.                 |
| `case`              | `:none`, `:up`, `:down`, `:title`, …  | Apply any `String#*case` method (built-in or custom).                       |
| `only`              | Symbol or Array                       | Restrict to specific columns.                                               |
| `except`            | Symbol or Array                       | Exclude specific columns.                                                   |
| `include_text_type` | `true` / `false`                      | Also sanitize `text` columns (skipped by default).                          |

## Behavior notes (built on `normalizes`)

Since Sanitization 2.0 is implemented on top of Rails' `normalizes`, normalization runs at **attribute assignment** time, not in a `before_save` callback. A few useful consequences:

- **Read-after-write returns the normalized value.** `person.name = " john "; person.name` returns `"john"` immediately. Validations see the cleaned value.
- **`where` / `find_by` hash conditions normalize the lookup value.** `User.where(email: "  RAW@X.COM  ")` matches a row stored as `"raw@x.com"`. Raw-SQL conditions (`where("email = ?", …)`) still bypass normalization.
- **Legacy un-normalized rows are not silently rewritten on save.** To migrate old data, reassign the attribute or call `record.normalize_attribute(:col)` (a built-in helper from `normalizes`).

Upgrading from 1.x? See the [CHANGELOG](CHANGELOG.md) for the full list of behavior changes.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `rake spec` to run the tests, or `bin/console` for an interactive prompt.

To run tests across all supported Rails versions:

```sh
bundle exec appraisal install
bundle exec appraisal rspec
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
