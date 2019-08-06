
		#
		# get latest updates from user
		#
		# return latest updates from everyone !
		#
		def update_data data
			req = UpdateRequest.parse data

			# prepare empty result message
			result = {
				events: [],
				strokes: [],
				messages: [],
			}
			now = Time.now.to_i
			user = User.first(token: req.user_token)
			if user.nil? or user.expired? then
				raise InvalidSession, "Session has expired!"
			end

      board = user.board
      if board.nil? or
        board.closed or
        board.board_group.token != req.session_token then
        raise InvalidSession, "No opened session found for board %s" % req.session_token
      end

      ref_stamp = user.last_update_time - req.update_interval

      User.transaction do |t|
        user.alive_expires_at = now + @config.user.liveness_timeout
        if not req.strokes.empty? then
          user.idle_expires_at = now + @config.user.idle_timeout
        end
        user.last_update_time = now

        user.save
      end

      board.update_data user, req.strokes
      @chat.update_data user, req.messages

      timelines = board.timelines.all(
        :id.gt => req.timeline_after
      )

      strokes = timelines.strokes.all(
        :zone.not => user.zone
      )

      strokes_collection = strokes.map{ |d| d.to_hash ref_stamp }
      events_collection = timelines.events.map{ |event| event.to_hash ref_stamp }
      messages = timelines.messages.all(
        user_dst: user.id
      )
      messages_collection = messages.map{ |message| message.to_hash }

      result = {
        events: events_collection,
        strokes: strokes_collection,
        messages: messages_collection,
      }

			return result
		end
