require_relative 'lib/sanitization/version'

Gem::Specification.new do |spec|
  spec.name          = "sanitization"
  spec.version       = Sanitization::VERSION
  spec.authors       = ["Carl Mercier"]
  spec.email         = ["foss@carlmercier.com"]

  spec.summary       = %q{Sanitization makes it easy to store slightly cleaner strings to your database.}
  spec.description   = %q{Sanitization makes it easy to store slightly cleaner strings to your database.}
  spec.homepage      = "https://github.com/cmer/sanitization"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cmer/sanitization"
  spec.metadata["changelog_uri"] = "https://github.com/cmer/sanitization"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency "activerecord"
  spec.add_runtime_dependency "activesupport"
  spec.add_development_dependency "appraisal"
end
