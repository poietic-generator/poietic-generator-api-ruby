/******************************************************************************/
/*                                                                            */
/*  Poietic Generator Reloaded is a multiplayer and collaborative art         */
/*  experience.                                                               */
/*                                                                            */
/*  Copyright (C) 2011 - Gnuside                                              */
/*                                                                            */
/*  This program is free software: you can redistribute it and/or modify it   */
/*  under the terms of the GNU Affero General Public License as published by  */
/*  the Free Software Foundation, either version 3 of the License, or (at     */
/*  your option) any later version.                                           */
/*                                                                            */
/*  This program is distributed in the hope that it will be useful, but       */
/*  WITHOUT ANY WARRANTY; without even the implied warranty of                */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero  */
/*  General Public License for more details.                                  */
/*                                                                            */
/*  You should have received a copy of the GNU Affero General Public License  */
/*  along with this program.  If not, see <http://www.gnu.org/licenses/>.     */
/*                                                                            */
/******************************************************************************/

// vim: set ts=4 sw=4 et:

/*jslint browser: true, nomen: true*/
/*global jQuery, document, noconsole, PoieticGen */

(function (PoieticGen, $) {
	"use strict";

	var DRAW_SESSION_UPDATE_INTERVAL = 1000,

		STATUS_INFORMATION = 1,
		STATUS_SUCCESS = 2,
		STATUS_REDIRECTION = 3,
		STATUS_SERVER_ERROR = 4,
		STATUS_BAD_REQUEST = 5;


	function DrawSession(callback) {
		var console = window.noconsole,
			self = this,
			_current_timeline_id = 0,
			_game = null,
			_dispatch_strokes_body,
			_session;

		this.user_id = null;
		this.zone_column_count = null;
		this.zone_line_count = null;
		this.user_zone = null;
		this.last_update_time = new Date();


		/**
		* Semi-Constructor
		*/
		this.initialize = function () {
			var user_id = $.cookie('user_id'),
				user_name = $.cookie('user_name'),
				session_opts = [],
				session_url = null,
				url_matches;

			url_matches = /\/session\/(\w+)\/draw/.exec(window.location);
			if (url_matches !== null && url_matches.length === 2) {
				_session = url_matches[1];
			} else {
				_session = ""; // Error
			}

			_game = new PoieticGen.Game();

			if (user_id !== null) {
				session_opts.push("user_id=" + user_id);
			}
			if (user_name !== null) {
				session_opts.push("user_name=" + user_name);
			}

			session_url = "/session/" + _session + "/draw/join.json?" + session_opts.join('&');

			// get session info from

			$.ajax({
				url: session_url,
				dataType: "json",
				type: 'GET',
				context: self,
				success: function (response) {
					console.log('edit_session/join response : ' + JSON.stringify(response));

					if (response.status === null || response.status[0] !== STATUS_SUCCESS) {
						self.treat_status_nok(response);
						return;
					}

					this.user_zone = response.user_zone;
					this.other_users = response.other_users;
					this.other_zones = response.other_zones;
					this.user_id = response.user_id;
					this.user_name = response.user_name;
					this.zone_column_count = response.zone_column_count;
					this.zone_line_count = response.zone_line_count;

					_current_timeline_id = response.timeline_id;

					$.cookie('user_id', this.user_id, {path: "/"});
					$.cookie('user_name', this.user_name, {path: "/"});
					// console.log('edit_session/join response mod : ' + JSON.stringify(this));

					console.log("gotcha!");

					callback(self);

					//console.log('edit_session/join post-callback ! observers = ' + JSON.stringify(_game.observers()));
					var all_zones = this.other_zones.concat([ this.user_zone ]),
						i;
					// handle other zone events
					for (i = 0; i < all_zones.length; i += 1) {
						console.log('edit_session/join on zone ' + JSON.stringify(all_zones[i]));
						self.dispatch_strokes(all_zones[i].content);
					}

					self.dispatch_messages(response.msg_history);

					window.setTimeout(self.update, DRAW_SESSION_UPDATE_INTERVAL);

					console.log('edit_session/join end');

				}
			});

			this.register(self);
		};


		/**
		* Retrieve the user name from given id
		*/
		this.get_user_name = function (id) {
			var i;
			if (id === this.user_id) {
				return this.user_name;
			}
			for (i = 0; i < this.other_users.length; i += 1) {
				if (id === this.other_users[i].id) {
					return this.other_users[i].name;
				}
			}
			return null;
		};


		/**
		* Treat not ok Status (!STATUS_SUCCESS)
		*/
		this.treat_status_nok = function (response) {
			var empty;
			if (response.status === null) {
				// error on server side
				empty = "argh";
			} else {
				switch (response.status[0]) {
				case STATUS_INFORMATION:
					break;
				case STATUS_SUCCESS:
					// ???
					break;
				case STATUS_REDIRECTION:
					// We got redirected for some reason, we do execute ourselfs
					console.log("STATUS_REDIRECTION --> Got redirected to '" + response.status[2] + "'");
					document.location.href = response.status[2];
					break;
				case STATUS_SERVER_ERROR:
					// FIXME : We got a server error, we should try to reload the page.
					break;
				case STATUS_BAD_REQUEST:
					// FIXME : OK ???
					break;
				}
			}
			return null;
		};

		/**
		*
		*/
		this.update = function () {

			var strokes_updates = [],
				messages_updates = [],
				req,
				i,
				observers = _game.observers();

			// skip if no user id assigned
			if (!self.user_id) {
				window.setTimeout(self.update, DRAW_SESSION_UPDATE_INTERVAL);
				return null;
			}

			// assign real values if objects are present
			if (observers.length < 1) {
				window.setTimeout(self.update, DRAW_SESSION_UPDATE_INTERVAL);
				return null;
			}

			for (i = 0; i < observers.length; i += 1) {
				if (observers[i].get_messages) {
					messages_updates = messages_updates.concat(messages_updates, observers[i].get_messages());
				}
				if (observers[i].get_strokes) {
					strokes_updates = strokes_updates.concat(strokes_updates, observers[i].get_strokes());
				}
			}

			console.log("edit_session/update: strokes_updates = " + JSON.stringify(strokes_updates));
			console.log("edit_session/update: messages_updates = " + JSON.stringify(messages_updates));

			req = {
				timeline_after : _current_timeline_id,

				strokes : strokes_updates,
				messages : messages_updates,

				update_interval : DRAW_SESSION_UPDATE_INTERVAL / 1000
			};

			console.log("edit_session/update: req = " + JSON.stringify(req));
			self.last_update_time = new Date();
			$.ajax({
				url: "/session/" + _session + "/draw/update.json",
				dataType: "json",
				data: JSON.stringify(req),
				type: 'POST',
				context: self,
				success: function (response) {
					console.log('edit_session/update response : ' + JSON.stringify(response));
					if (response.status === null || response.status[0] !== STATUS_SUCCESS) {
						self.treat_status_nok(response);
					} else {
						self.dispatch_events(response.events);
						self.dispatch_strokes(response.strokes);
						self.dispatch_messages(response.messages);

						window.setTimeout(self.update, DRAW_SESSION_UPDATE_INTERVAL);
					}
				},
				error: function (response) {
					window.setTimeout(self.update, DRAW_SESSION_UPDATE_INTERVAL * 2);
				}
			});

		};


		this.dispatch = function (events) {
			var i;

			for (i = 0; i < events.length; i += 1) {
				if ((events[i].id) && (_current_timeline_id < events[i].id)) {
					_current_timeline_id = events[i].id;
				}
				// Make absolute times
				if (events[i].diffstamp) {
					events[i].timestamp = events[i].diffstamp + self.last_update_time.getTime() / 1000;
				} else {
					events[i].timestamp = self.last_update_time.getTime() / 1000;
				}
			}
		};

		this.dispatch_events = function (events) {
			self.dispatch(events);
			_game.dispatch_events(events);
		};

		this.dispatch_strokes = function (strokes) {
			self.dispatch(strokes);
			_game.dispatch_strokes(strokes);
		};

		this.dispatch_messages = function (messages) {
			self.dispatch(messages);
			_game.dispatch_messages(messages);
		};


		this.handle_event = function (ev) {
			var i;
			console.log("edit_session/handle_event : " + JSON.stringify(ev));
			switch (ev.type) {
			case "join":
				this.other_users.push(ev.desc.user);
				break;
			case "leave":
				for (i = 0; i < this.other_users.length; i += 1) {
					if (ev.desc.user.id === this.other_users[i].id) {
						this.other_users.splice(i, 1);
					}
				}
				break;
			default: // other events are ignored
				break;
			}
		};

		this.register = function (p_observer) {
			_game.register(p_observer);
		};

		this.initialize();
	}

	// export
	PoieticGen.DrawSession = DrawSession;
}(PoieticGen, jQuery));

