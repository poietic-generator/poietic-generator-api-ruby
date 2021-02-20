

require_relative 'spec_helper'

require 'poieticgen/cli'

describe PoieticGen::Cli do
	let(:cli) { TimeCost::CLI.new }

	describe '.list' do
		it "can be called" do
		end

		it "accepts an argument" do
		end

		it "displays existing groups" do
		end

		it "displays existing open sessions in groups" do
		end

		it "option --all adds displays closed sessions in groups" do
			# destroy all
			# create group
			# create session
			# play in session
			# leave
			# create another session (keep alive?)
			cli = PoieticGen::Cli.start(['list','--all'])
		end
	end

end
