# frozen_string_literal: true

require_relative "lib/rimcache/version"

Gem::Specification.new do |spec|
  spec.name = "rimcache"
  spec.version = Rimcache::VERSION
  spec.authors = ["Duncan McKee"]
  spec.email = ["mckeed+rubygems@gmail.com"]

  spec.summary = "Keep commonly-used records in memory with expiration coordinated via the Rails cache."
  spec.description =
    <<~DESC
      "Caches" commonly-used objects by just storing them frozen in a global hash.
      Expiration is handled via Rails low-level caching or an ActiveSupport::Cache
    DESC

  spec.homepage = "https://github.com/mckeed/rimcache"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mckeed/rimcache"
  spec.metadata["changelog_uri"] = "https://github.com/mckeed/rimcache/tree/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activesupport", "> 6.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
