

require_relative 'spec_helper'

#require 'timecost/author_list'

#describe TimeCost::AuthorList do
#	let(:list) { TimeCost::AuthorList.new }
#	let(:first) { "Foo <foo@example.com>" }
#	let(:second) { "Bar <bar@example.com>" }
#
#	describe '.new' do
#		it "can be created without arguments" do
#			assert_instance_of TimeCost::AuthorList, list
#		end
#	end
#
#	describe '.add' do
#		it "must accept adding authors" do
#			assert_respond_to list, :add
#
#			list.add first
#			list.add second
#		end
#
#		it "must assign a different id to different authors" do
#			list.add first
#			list.add second
#			id_foo = list.parse first
#			id_bar = list.parse second
#			refute_equal id_foo, id_bar
#		end
#	end
#
#	describe '.size' do 
#		it "must be zero in the beginning" do
#			assert_equal list.size, 0
#		end
#
#		it "must grow while adding authors" do
#			list.add first
#			assert_equal list.size, 1
#			list.add second
#			assert_equal list.size, 2
#		end
#	end
#
#	describe '.alias' do
#		it "must accept aliases for authors" do 
#			assert_respond_to list, :alias
#
#			list.add first
#			list.alias first, second 
#		end
#
#		it "must assign the same id to aliases authors" do
#			list.add first
#			list.alias first, second
#
#			id_foo = list.parse first
#			id_bar = list.parse second
#			refute_equal id_foo, id_bar
#		end
#	end
#end
