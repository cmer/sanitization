# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

The `sanitization` gem is a Ruby gem that adds automatic string sanitization to ActiveRecord models via a `before_save` callback. It can strip whitespace, collapse multiple spaces, convert empty strings to nil, and apply case transformations.

## Commands

```bash
# Run tests (default rake task)
rake spec

# Run tests with RSpec directly
bundle exec rspec

# Run a single test file or example
bundle exec rspec spec/sanitization_spec.rb
bundle exec rspec spec/sanitization_spec.rb:42

# Run tests across all supported Rails versions (6, 7, 8)
bundle exec appraisal rspec

# Run tests for a specific Rails version
bundle exec appraisal rails-8 rspec

# Install appraisal gemfiles after changing Appraisals file
bundle exec appraisal install
```

## Architecture

The gem has three core files:

- **`lib/sanitization/configuration.rb`** - `Sanitization::Configuration` class with global defaults (strip, collapse, case, nullify, include_text_type). `simple_defaults!` is a shortcut that enables strip + collapse + nullify.
- **`lib/sanitization/active_record_extension.rb`** - The core logic. `ClassMethods.sanitizes()` introspects table columns, filters by type (string, optionally text), validates options, and stores per-column config in `@sanitization__store`. Registers a `before_save` callback that applies transformations in order: strip -> collapse -> nullify -> case.
- **`lib/sanitization.rb`** - Entry point that includes `ActiveRecordExtension` into `ActiveRecord::Base` via `class_eval`.

## Testing

Tests use RSpec with an in-memory SQLite database. The `spec_helper.rb` creates a `people` table with string, text, date, and integer columns. A custom `String#leetcase` method is defined for testing custom case transformations.

CI runs on Ruby 3.2, 3.3, 3.4 against Rails 6.1, 7.0, and 8.0 via Appraisal.

Note: ActiveSupport 7+ changed `titlecase` behavior (it strips leading spaces), which affects test expectations between Rails versions.

## Changelog Workflow

Track changes in the `## Unreleased` section of `CHANGELOG.md` as they are made. When a new version is released, rename the `## Unreleased` heading to the version number (e.g., `# 1.3`) and add a fresh `## Unreleased` section above it.
