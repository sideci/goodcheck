lib = File.expand_path("../lib", __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "hello"
  spec.version       = "1.0.0"
  spec.authors       = ["Soutaro Matsumoto"]
  spec.email         = ["matsumoto@soutaro.com"]

  spec.summary       = "Regexp based customizable linter"
  spec.description   = "Regexp based customizable linter"
  spec.homepage      = "https://github.com/sider/goodcheck"

  spec.files         = []
  spec.bindir        = "exe"
  spec.executables   = ["exe/goodcheck"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.4.0'
end
