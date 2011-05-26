
require 'dm-core'

class Event
	include DataMapper::Resource

	property :id,	Serial
	property :type,	String, :required => true
	property :desc, String, :required => true
end

