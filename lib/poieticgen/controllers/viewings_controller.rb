
		#
		# Return a session snapshot
		#
		def snapshot params
			req = SnapshotRequest.parse params
			result = {}

			User.transaction do |t|
				board = Board.from_token req.session_token
				raise InvalidSession, "Invalid session" if board.nil?

				# ignore session_id from the viewer point of view but use server one
				# to distinguish old sessions/old users

				timeline_id = 0
				date_range = -1
				timestamp = -1

				# we take a snapshot one second in the past to be sure we will get
				# a complete second.
				if req.date == -1 then
					# get the current state, select only this session
					users_db = board.users.all(did_expire: false)
					users = users_db.map{ |u| u.to_hash }
					zones = users_db.map{ |u| u.zone.to_desc_hash Zone::DESCRIPTION_FULL }

					timeline_id = Timeline.last_id board
				else
					end_session = if board.end_timestamp <= 0
					                then Time.now.to_i - 1
					              else board.end_timestamp
					              end
					# retrieve the total duration of the game
					date_range = end_session - board.timestamp

					# retrieve stroke_max and event_max

					if req.date != 0 then
						if req.date > 0 then
							# get the state from the beginning.
							absolute_time = board.timestamp + req.date
						else
							# get the state from end of session.
							absolute_time = end_session + req.date + 1
						end

						timestamp = absolute_time - board.timestamp

						# retrieve users and zones
						zones = board.load_board absolute_time

						users = zones.map{ |i,z| z.user.to_hash }
						zones = zones.map{ |i,z| z.to_desc_hash Zone::DESCRIPTION_FULL }
					else
						timestamp = 0
						users = zones = [] # no events => no users => no zones
					end
				end

				# return snapshot params (user, zone), start_time, and
				# duration of the session since then.
				result = {
					users: users, # TODO: unused by the viewer
					zones: zones,
					zone_column_count: @config.board.width,
					zone_line_count: @config.board.height,
					timeline_id: timeline_id,
					timestamp: timestamp, # time between the session start and the requested date
					date_range: date_range, # total time of session
					id: req.id
				}

			end

			return result
		end

		#
		# Get strokes and events for a non-user viewer.
		#
		def update_view params
			req = UpdateViewRequest.parse params
			result = {}
		  strokes_collection = []
			events_collection = []
			timestamp = 0
			max_timestamp = -1
			date_range = 0

      # test if session_token is defined
			board = Board.from_token req.session_token
			raise InvalidSession, "Invalid session" if board.nil?

			if req.view_mode == UpdateViewRequest::REAL_TIME_VIEW then
			  User.transaction do #NC:SMALL
			    # Get events and strokes between req.timeline_after and req.duration
				  timelines = board.timelines.all(:id.gte => req.timeline_after)

				  srk_req = timelines.strokes
				  evt_req = timelines.events

				  # Use the first element as a temporal reference
				  first_timeline = timelines.first(order: [:id.asc])

          if first_timeline then
				    strokes_collection = srk_req.map do |s|
					    s.to_hash first_timeline.timestamp
				    end

				    events_collection = evt_req.map do |e|
					    e.to_hash first_timeline.timestamp
				    end
				  end
			  end

			elsif req.view_mode == UpdateViewRequest::HISTORY_VIEW then
			  User.transaction do #NC:SMALL
          end_session = if board.end_timestamp <= 0
                          then Time.now.to_i - 1
                        else board.end_timestamp
                        end
				  # retrieve the total duration of the game
				  date_range = end_session - board.timestamp

				  session_timelines = board.timelines

				  if req.last_max_timestamp > 0 then
					  max_timestamp = req.last_max_timestamp + req.duration * 2
					  # Events between the requested timestamp and (timestamp + duration)
					  timelines = session_timelines.all(
						  :timestamp.gt => board.timestamp + req.last_max_timestamp,
						  :timestamp.lte => board.timestamp + max_timestamp
					  )
				  else
					  max_timestamp = req.duration * 2
					  timelines = session_timelines.all(
						  :timestamp.lte => board.timestamp + max_timestamp
					  )
				  end

				  if not timelines.empty? then
					  srk_req = timelines.strokes
					  strokes_collection = srk_req.map{ |s| s.to_hash (board.timestamp + req.since) }

					  evt_req = timelines.events
					  events_collection = evt_req.map{ |e| e.to_hash (board.timestamp + req.since) }

					  timestamp = timelines.first.timestamp - board.timestamp
				  end
				end
			else
				raise RuntimeError, "Unknown view mode %d" % req.view_mode
			end

			result = {
				events: events_collection,
				strokes: strokes_collection,
				timestamp: timestamp, # relative to the start of the game session
				max_timestamp: max_timestamp,
				date_range: date_range, # total time of session
				id: req.id,
			}
			return result
		end
