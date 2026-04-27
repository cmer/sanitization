## Unreleased
* **BREAKING CHANGE:** Minimum Rails version is now 7.1 (dropped Rails 6.x and 7.0)
* **BREAKING CHANGE:** Minimum Ruby version is now 3.2
* Added support for Rails 7.1 and 7.2 in test matrix

# 1.2
* Official support for Rails 8
* Official support for Ruby 3.4
* Deprecated support for Ruby < 3.2

# 1.1.4
* Official support for Ruby 3.1

# 1.1.3
* Official support for Rails 7

# 1.1.2
* Bug fixes

# 1.1.1
* Changed `sanitization` method to `sanitizes` as the new preferred way. `sanitization` still works and is an alias of `sanitizes`.

# 1.1.0
* **BREAKING CHANGE:** By default, Sanitization now does nothing. A configuration block should be used to set your desired defaults. Add `Sanitization.simple_defaults!` to `config/initializers/sanitization.rb` for version 1.0.x defaults.
* Added support for configuration block.


# 1.0.0
* Initial Release
