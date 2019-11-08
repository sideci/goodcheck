
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "goodcheck/version"

Gem::Specification.new do |spec|
  spec.name          = "goodcheck"
  spec.version       = Goodcheck::VERSION
  spec.authors       = ["Soutaro Matsumoto"]
  spec.email         = ["matsumoto@soutaro.com"]

  spec.summary       = "Regexp based customizable linter"
  spec.description   = "Regexp based customizable linter"
  spec.homepage      = "https://github.com/sider/goodcheck"
  spec.licenses      = ["MIT"]

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.4.0'

  spec.add_development_dependency "bundler", ">= 1.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.3.6"

  spec.add_runtime_dependency "activesupport", ">= 4.0", "< 7.0"
  spec.add_runtime_dependency "strong_json", "~> 1.1.0"
  spec.add_runtime_dependency "rainbow", "~> 3.0.0"
  spec.add_runtime_dependency "httpclient", "~> 2.8.3"
end
