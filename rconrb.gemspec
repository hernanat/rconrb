require_relative 'lib/rcon/version'

Gem::Specification.new do |spec|
  spec.name          = "rconrb"
  spec.version       = Rcon::VERSION
  spec.authors       = ["Anthony Felix Hernandez"]
  spec.email         = ["ant@antfeedr.com"]

  spec.summary       = %q{An flexible RCON client written in Ruby, based on the Source RCON protocol.}
  spec.homepage      = "https://github.com/hernanat/rconrb"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["documentation_uri"] = "https://rubydoc.info/github/hernanat/rconrb"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "pry"
  spec.add_development_dependency "yard", "~> 0.9.9"
end
