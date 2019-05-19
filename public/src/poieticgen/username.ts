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

/*jslint browser: true, continue: true*/
/*global $, jQuery, document, console, PoieticGen, VIEW_SESSION_TYPE_REALTIME */

(function (PoieticGen) {
	// vim: set ts=4 sw=4 et:
	"use strict";

	function Username(p_options) {
		//var console = { log: function() {} };

		this.name = "Username";

		var self = this,
			session,
			onupdate_fn;

		/**
		* Constructor
		*/
		this.initialize = function (p_options) {
			// fix options if needed
			p_options = p_options || {};

			// set variables from options
			session = p_options.session || undefined;
			onupdate_fn = p_options.onupdate || undefined;

			onupdate_fn(session.user_name);			
			session.register(self);
		};


		/**
		* Handle user-related (join/leave) events
		*/
		this.handle_event = function (ev) {
			//var console = window.noconsole;

			if (ev.type === 'rename') {
				console.log('Username event for ' + ev.type);
			}
		};

		this.change = function (name) {
			// emit something on the network
			// then change name locally
			onupdate_fn(name);
		};

		// call constructor
		this.initialize(p_options);
	}

	PoieticGen.Username = Username;

}(PoieticGen));

