# frozen_string_literal: true

require_relative "lib/chieftain/version"

Gem::Specification.new do |spec|
  spec.name = "chieftain"
  spec.version = Chieftain::VERSION
  spec.authors = ["Peter Wood"]
  spec.email = ["pw0470@gmail.com"]
  spec.licenses = ["Apache-2.0"]

  spec.summary = "An implementation of the Command design pattern in Ruby."
  spec.description = "An implementation of the command design pattern that attempts "\
                     "to simplify usage by enchancing the offering making use of the "\
                     "facilities offered by the Ruby language."
  spec.homepage = "https://github.com/free-beer/chieftain"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/free-beer/chieftain"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
