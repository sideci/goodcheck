require_relative "lib/goodcheck/version"

Gem::Specification.new do |spec|
  spec.name          = "goodcheck"
  spec.version       = Goodcheck::VERSION
  spec.authors       = ["Sider Corporation"]
  spec.email         = ["support@siderlabs.com"]

  spec.summary       = "Regexp based customizable linter."
  spec.description   = "Goodcheck is a regexp based linter that allows you to define custom rules in a YAML file."
  spec.homepage      = "https://sider.github.io/goodcheck/"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sider/goodcheck"
  spec.metadata["changelog_uri"] = "https://github.com/sider/goodcheck/blob/master/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/sider/goodcheck/issues"

  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "exe/goodcheck", "lib/**/*.rb"]
  spec.bindir        = "exe"
  spec.executables   = ["goodcheck"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.add_development_dependency "bundler", ">= 1.16"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "minitest", ">= 5.0"
  spec.add_development_dependency "simplecov", ">= 0.18"

  spec.add_runtime_dependency "strong_json", ">= 1.1", "< 2.2"
  spec.add_runtime_dependency "rainbow", ">= 3.0", "< 4.0"
  spec.add_runtime_dependency "psych", ">= 3.1", "< 5.0" # NOTE: Needed for old Ruby versions (<= 2.5)
end
