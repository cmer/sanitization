# 2.0
* **BREAKING CHANGE:** Minimum Rails version is now 7.1 (dropped Rails 6.x and 7.0)
* **BREAKING CHANGE:** Minimum Ruby version is now 3.2
* Added support for Rails 7.1 and 7.2 in test matrix
* Reimplemented internals on top of Rails 7.1's `ActiveRecord::Base.normalizes`. The `sanitizes` DSL is unchanged, but normalization now runs at **attribute assignment time** instead of `before_save`. This produces a few subtle behavior changes:
  * **Read-after-write returns the normalized value.** `person.name = " john "; person.name` now returns `"john"` immediately, not `" john "`. Validations and any pre-save reads see normalized values.
  * **Legacy un-normalized rows are no longer rewritten on every save.** Previously the `before_save` callback rewrote every declared column on each save, opportunistically cleaning up old data. To migrate legacy rows now, reassign the attribute or call `record.normalize_attribute(:col)` before saving.
  * **`where` and `find_by` hash conditions now normalize their input.** `User.where(email: " X@Y.com ")` will match a row stored as `"x@y.com"`. Raw-SQL conditions (`where("email = ?", ...)`) still bypass normalization.
  * Apps upgrading from Rails < 7.1 should set `config.active_record.marshalling_format_version = 7.1` to avoid `TypeError` when marshalling records with normalized attributes.

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
