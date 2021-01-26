# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/poieticgen/version'

Gem::Specification.new do |spec|
  spec.name          = 'poieticgen'
  spec.version       = PoieticGen::VERSION
  spec.authors       = ['Glenn Y. Rolland']
  spec.email         = ['glenux@glenux.net']
  spec.summary       = 'Poietic Generator is a multiplayer and collaborative art experiment.'
  spec.description   = <<-MARK
		The Poietic Generator is a free social network game designed in order
		to study crowd phenomena such as the ones happening in commercial
		social networks sites, various online communities, financial markets,
		as well as in everyday conversations.

		The game may be envisioned as a 100% "Game of Life", that is to say a
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
  MARK
  spec.homepage      = 'https://poietic-generator.net'
  spec.license       = 'AGPL'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4'
end
