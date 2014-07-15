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

/*jslint nomen:true*/
/*global document, window, noconsole, jQuery, PoieticGen*/

// vim: set ts=4 sw=4 et:

(function (PoieticGen, $) {
	"use strict";

	var VIEW_SESSION_UPDATE_INTERVAL = 1000,
		VIEW_PLAY_UPDATE_INTERVAL = VIEW_SESSION_UPDATE_INTERVAL / 1000,
		VIEW_SESSION_JOIN_RETRY_INTERVAL = 1000,

		STATUS_INFORMATION = 1,
		STATUS_SUCCESS = 2,
		STATUS_REDIRECTION = 3,
		STATUS_SERVER_ERROR = 4,
		STATUS_BAD_REQUEST = 5,

		REAL_TIME_VIEW = 0,
		HISTORY_VIEW = 1;


	function ViewSession(callback, p_slider) {
		var console = window.noconsole,
			self = this,
			_current_timeline_id = -1,
			_slider = null,
			_game = null,

			_last_join_start_time = 0,

			_timer = null,
			_play_speed = 1,
			_get_elapsed_time,
			_get_current_time,
			_view_type = REAL_TIME_VIEW,
			_last_join_timestamp = 0,
			_last_update_max_timestamp = -1,
			_request_id = 0,
			_session = "";

		this.zone_column_count = null;
		this.zone_line_count = null;


		/*
		 * Date utilities 
		 */

		_get_elapsed_time = function () {
			return _get_current_time() - _last_join_start_time;
		};

		_get_current_time = function () {
			return Math.floor((new Date()).getTime() / 1000);
		};


		/**
		 * Semi-Constructor
		 */
		this.initialize = function (slider) {

			var url_matches;

			url_matches = /\/session\/(\w+)\/view/.exec(window.location);
			if (url_matches !== null && url_matches.length === 2) {
				_session = url_matches[1];
			} else {
				_session = ""; // Error
			}

			_request_id = 0;
			_game = new PoieticGen.Game();
			_slider = slider;
			_slider.set_animation_interval(1);

			_slider.edited(function () {
				var date = _slider.value();
				console.log('User history change: ' + date);
				/* if (date >= _slider.maximum()) {
					_view_type = REAL_TIME_VIEW;
				} else {
					_view_type = HISTORY_VIEW;
				} */
				self.play(date);
			});
		};

		this.join_view_session = function (date) {

			_game.reset(); // Observers needs to be cleared because callback reregister all

			if (date !== -1) {
				_view_type = HISTORY_VIEW;
			} else {
				_view_type = REAL_TIME_VIEW;
			}

			_request_id += 1;

			// get session info from
			$.ajax({
				url: "/session/" + _session + "/view/snapshot.json",
				data: {
					date: date,
					id: _request_id
				},
				dataType: "json",
				type: 'GET',
				context: self,
				success: function (response) {
					var i;

					if (response.status === null || response.status[0] !== STATUS_SUCCESS) {
						self.treat_status_nok(response);
						return;
					}

					// Ensure that this response is associated to the last join request
					if (response.id !== _request_id) {
						return;
					}

					console.log('view_session/join response : ' + JSON.stringify(response));

					this.zone_column_count = response.zone_column_count;
					this.zone_line_count = response.zone_line_count;

					_last_join_start_time = _get_current_time();
					_last_join_timestamp = response.timestamp;

					_current_timeline_id = response.timeline_id;
					// console.log('view_session/join response mod : ' + JSON.stringify(this) );

					_last_update_max_timestamp = response.timestamp;

					self.other_zones = response.zones;

					callback(self);

					//console.log('view_session/join post-callback ! observers = ' + JSON.stringify( _game.observers() ));
					// handle other zone events
					for (i = 0; i < self.other_zones.length; i += 1) {
						//console.log('view_session/join on zone ' + JSON.stringify(self.other_zones[i]));
						self.dispatch_strokes(self.other_zones[i].content, 0);
					}

					if (_view_type === HISTORY_VIEW) {
						_slider.set_range(0, response.date_range);
					}

					self.set_timer(self.update, VIEW_SESSION_UPDATE_INTERVAL);

					console.log('view_session/join end');
				},
				error: function (response) {
					self.set_timer(self.join_view_session, VIEW_SESSION_JOIN_RETRY_INTERVAL);
				}
			});
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
					console.log("STATUS_REDIRECTION --> Got redirected to :" + response.status[2]);
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

			var req;

			// assign real values if objects are present
			if (_game.observers().length < 1) {
				self.set_timer(self.update, VIEW_SESSION_UPDATE_INTERVAL);
				return null;
			}

			_request_id += 1;

			req = {
				timeline_after : _current_timeline_id + 1,
				last_max_timestamp : _last_update_max_timestamp,

				duration: VIEW_PLAY_UPDATE_INTERVAL * _play_speed,
				since : _last_join_timestamp,
				id : _request_id,
				view_mode : _view_type
			};

			console.log("view_session/update: req = " + JSON.stringify(req));
			$.ajax({
				url: "/session/" + _session + "/view/update.json",
				dataType: "json",
				data: req,
				type: 'GET',
				context: self,
				success: function (response) {

					if (response.status === null || response.status[0] !== STATUS_SUCCESS) {
						self.treat_status_nok(response);
					} else {
						if (_request_id !== response.id) {
							return;
						}

						var last_update_timestamp = 0;

						if (_view_type === HISTORY_VIEW) {
							last_update_timestamp = parseInt(response.timestamp, 10);
							/* if (last_update_timestamp < 0 || last_update_timestamp >= _slider.maximum() - 1) {
								_view_type = REAL_TIME_VIEW;
								console.log('view_session/update real time!');
							} */

							_slider.set_maximum(response.date_range);
							_slider.set_value(response.max_timestamp);

							_last_update_max_timestamp = response.max_timestamp;
						}

						self.dispatch_events(response.events, last_update_timestamp);
						self.dispatch_strokes(response.strokes, last_update_timestamp);
					}

					self.set_timer(self.update, VIEW_SESSION_UPDATE_INTERVAL);
				},
				error: function (response) {
					self.set_timer(self.update, VIEW_SESSION_UPDATE_INTERVAL);
				}
			});

		};

		this.adjust_time = function (events, last_update_timestamp) {
			var i, seconds = 0, evt_diffstamp;

			if (events.length < 1) {
				return events;
			}

			if (_view_type === REAL_TIME_VIEW) {
				// We want the first stroke now and the others synchronized
				seconds = parseInt(events[0].diffstamp, 10);

				// Search min diffstamp
				for (i = 1; i < events.length; i += 1) {
					evt_diffstamp = parseInt(events[i].diffstamp, 10);
					if (seconds > evt_diffstamp) {
						seconds = evt_diffstamp;
					}
				}

			} else {
				// diffstamps are relative to the local start date
				seconds = _get_elapsed_time();
			}

			//console.log('view_session/update seconds : ' + seconds);

			for (i = 0; i < events.length; i += 1) {
				// Make absolute times
				if (events[i].diffstamp) {
					events[i].diffstamp = parseInt(events[i].diffstamp, 10) - seconds;
					events[i].timestamp = events[i].diffstamp + _last_join_start_time;
				} else {
					events[i].timestamp = _last_join_start_time;
				}
			}

			//console.log('view_session/update adjust_time : ' + JSON.stringify(events));

			return events;
		};

		this.update_current_timeline = function (events) {
			var i;

			// Retrieve the new timeline_id
			for (i = 0; i < events.length; i += 1) {
				if (events[i].id && _current_timeline_id < events[i].id) {
					_current_timeline_id = events[i].id;
				}
			}
		};

		this.dispatch_events = function (events, last_update_timestamp) {
			events = self.adjust_time(events, last_update_timestamp);
			self.update_current_timeline(events);
			_game.dispatch_events(events);
		};

		this.dispatch_strokes = function (strokes, last_update_timestamp) {
			strokes = self.adjust_time(strokes, last_update_timestamp);
			self.update_current_timeline(strokes);
			_game.dispatch_strokes(strokes);
		};

		this.dispatch_reset = function () {
			var o, observers = _game.observers();
			for (o = 0; o < observers.length; o += 1) {
				if (observers[o].handle_reset) {
					observers[o].handle_reset(self);
				}
			}
		};

		this.register = function (p_observer) {
			_game.register(p_observer);
		};

		this.clear_timer = function () {
			if (null !== _timer) {
				window.clearTimeout(_timer);
				_timer = null;
			}
		};

		this.clear_all_timers = function () {
			self.clear_timer();
			_game.clear();
		};

		this.set_timer = function (fn, interval) {
			self.clear_timer();
			_timer = window.setTimeout(fn, interval);
		};


		/**
		 * Play from current position
		 */
		this.current = function () {
			console.log("view_session/current");
			self.play(-1);
		};

		/**
		 * Replay from beginning
		 */
		this.restart = function () {
			console.log("view_session/restart");
			_slider.set_value(0);
			self.play(0);
		};

		/**
		 * Play with date
		 */
		this.play = function (date) {
			self.clear_all_timers();
			self.join_view_session(date);
			self.dispatch_reset();
		};

		this.initialize(p_slider);
	}

	// expose scope objects
	PoieticGen.ViewSession = ViewSession;

}(PoieticGen, jQuery));

