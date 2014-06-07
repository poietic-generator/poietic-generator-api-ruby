# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'poieticgen/version'

Gem::Specification.new do |spec|
  spec.name          = "poieticgen"
  spec.version       = PoieticGen::VERSION
  spec.authors       = ["Glenn Y. Rolland"]
  spec.email         = ["glenn.rolland@gnuside.com"]
  spec.summary       = %q{Poietic Generator is a multiplayer and collaborative art experiment.}
  spec.description   = %q{
		The Poietic Generator is a free social network game designed in order
		to study crowd phenomena such as the ones happening in commercial
		social networks sites, various online communities, financial markets,
		as well as in everyday conversations.

		The game may be envisioned as a 100% « Game of Life », that is to say a
		cellular automata where every single cell is manipulated by a single
		human being. It allows everybody (10, 100, 1000 or more people, all
		together), regardless of his/her language, culture and educational
		background, to participate in real time (with a PC or mobile device) in
		the process of self-organization at work in the continuous emergence of
		a global picture.

		The goal of the Poietic Generator is to give to citizen scientists a
		direct observation and a better understanding of crowd phenomena
		(self-organization, temporal behaviours, panic, etc.), as well as
		providing data to scientists in order to challenge various theories
		which may predict some global behaviours and dynamics.

		The Poietic Generator is known as one of the historical works of
		digital art, interactive art, generative art and net.art. The project
		has been launched a long time ago (1986) by Olivier Auber at a time
		when the technology did not allow massive experiments. Nevertheless,
		small scale sessions performed over the web or experimental networks
		with various online communities have provided a good proof of concept.
  }
  spec.homepage      = "http://poietic-generator.net"
  spec.license       = "AGPL"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.1'
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "html2haml"
  spec.add_development_dependency "capistrano", "~> 2.15"
  spec.add_development_dependency "capistrano-ext"

  spec.add_runtime_dependency "unicorn"
  spec.add_runtime_dependency "sinatra" # :require => "sinatra/base"
  spec.add_runtime_dependency "sinatra-reloader"
  spec.add_runtime_dependency "async_sinatra"
  spec.add_runtime_dependency "sinatra-flash"
  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "haml"
  spec.add_runtime_dependency "sass"
  spec.add_runtime_dependency "compass"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "datamapper"
  spec.add_runtime_dependency "dm-migrations"
  spec.add_runtime_dependency "dm-transactions"
  spec.add_runtime_dependency "dm-mysql-adapter"
  spec.add_runtime_dependency "dm-aggregates"
  spec.add_runtime_dependency "dm-constraints"
  spec.add_runtime_dependency "dm-types"
  spec.add_runtime_dependency "inifile"
  spec.add_runtime_dependency "extlib"
  spec.add_runtime_dependency "rdebug"
 # spec.add_runtime_dependency "thin"
  spec.add_runtime_dependency "oily_png"
  spec.add_runtime_dependency "foreman"
end
