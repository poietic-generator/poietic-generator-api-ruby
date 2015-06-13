
module PoieticGen
	class Transaction

		def self.handle_deadlock_exception e, t, context
			# Deadlock found when trying to get lock; try restarting transaction
			if e.code == 1213 and e.sqlstate == "40001" then
				# InnoDB do a rollback automatically
				# FIXME: a fatal error is raised by dm-transactions
				STDERR.puts "Deadlock found in %s" % context
				t.state = :commit
			else
				t.rollback
			end
		end
	end
end

