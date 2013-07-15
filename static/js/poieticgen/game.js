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

	var GAME_UPDATE_INTERVAL = 1000,
		EVENT_EVENT = 0,
		STROKE_EVENT = 1,
		MESSAGE_EVENT = 2;

	function Game() {
		var console = window.console,
			self = this,
			_observers = [],
			_events = [],
			_older_event,
			_remove_event;

		this.run = function () {
			var e, event_desc, event, type, o,
				to_remove_count = 0, interval;

			_events.sort(function (a, b) {
				if (a.event.id < b.event.id) {
					return -1;
				}
				if (a.event.id > b.event.id) {
					return 1;
				}
				return 0;
			});

			for (e = 0; e < _events.length; e += 1) {
				event_desc = _events[e];
				event = event_desc.event;

				console.log("game.run sorted events: " + JSON.stringify(event));

				if (event.timestamp <= (new Date()).getTime() / 1000) {
					type = event_desc.type;

					console.log("now " + event.timestamp + " timeline " + event.id);

					for (o = 0; o < _observers.length; o += 1) {
						if (type === EVENT_EVENT) {
							if (_observers[o].handle_event) {
								console.log("EVENT_EVENT");
								_observers[o].handle_event(event);
							}
						} else if (type === STROKE_EVENT) {
							if (_observers[o].handle_stroke) {
								console.log("STROKE_EVENT");
								_observers[o].handle_stroke(event);
							}
						} else if (type === MESSAGE_EVENT) {
							if (_observers[o].handle_message) {
								console.log("MESSAGE_EVENT");
								_observers[o].handle_message(event);
							}
						}
					}

					to_remove_count += 1;
				} else {
					break;
				}
			}

			if (to_remove_count > 0) {
				_events.splice(0, to_remove_count);
			}

			if (_events.length > 0) {
				interval = _events[0].event.timestamp * 1000 - (new Date()).getTime();
			} else {
				interval = GAME_UPDATE_INTERVAL;
			}

			window.setTimeout(self.run, interval);
		};

		this.dispatch_events = function (events) {
			self.dispatch(events, EVENT_EVENT);
		};

		this.dispatch_strokes = function (strokes) {
			self.dispatch(strokes, STROKE_EVENT);
		};

		this.dispatch_messages = function (messages) {
			self.dispatch(messages, MESSAGE_EVENT);
		};

		this.dispatch = function (events, type) {
			var e;
			for (e = 0; e < events.length; e += 1) {
				_events.push({ event: events[e], type: type });
			}
		};

		this.clear = function () {
			_events = [];
		};

		this.register = function (observer) {
			_observers.push(observer);
		};

		this.observers = function () {
			return _observers;
		};

		/**
		 * Returns the first event to be triggered.
		 * Note: do not call this function if _events is empty.
		 */
		_older_event = function () {
			var min_event = _events[0], e;

			for (e = 1; e < _events.length; e += 1) {
				if (_events[e].event.diffstamp < min_event.event.diffstamp) {
					min_event = e;
				}
			}

			return min_event;
		};

		_remove_event = function (e) {
			var i;
			for (i = 0; i < _events.length; i += 1) {
				if (e === _events[i]) {
					_events.splice(i, 1);
					return;
				}
			}
		};

		self.run();
	}

	// expose scope objects
	PoieticGen.Game = Game;

}(PoieticGen, jQuery));

