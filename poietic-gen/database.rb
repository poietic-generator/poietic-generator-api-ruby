
class User
	MAX_IDLE = 60

	include DataMapper::Resource

	property :id,	Serial
	property :session,	String, :required => true
	property :name,	String, :required => true
	property :created_at,	DateTime, :required => true
	property :expires_at, DateTime, :required => true
end

