# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tws_gecko/version"

Gem::Specification.new do |spec|
  spec.name          = "tws_gecko"
  spec.version       = TwsGecko::VERSION
  spec.authors       = ["asd456fgh7789"]
  spec.email         = ["asd456fgh7789ss@gmail.com"]

  spec.summary       = %q{"台股壁虎"}
  spec.description   = <<-DESCRIPTION


  DESCRIPTION
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = Dir['lib/**/*.rb']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }

  spec.require_paths = ['lib']

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "httpclient"
  spec.add_dependency "faker"
  spec.add_dependency "nokogiri"
end
