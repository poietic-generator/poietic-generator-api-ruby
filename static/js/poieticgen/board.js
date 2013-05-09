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

/*jslint browser: true*/
/*global $, jQuery, document, Zone, console */

// FIXME expose board objects to window

(function () {

	"use strict";

	/**
	* Global view
	*/
	function Board(p_session) {
		//var console = window.noconsole;

		var self = this,
			realCanvas,
			context,
			zones,
			users,
			session;

		this.name = "Board";



		/**
		* Constructor
		*/
		this.initialize = function (p_session) {

			// loop vars
			var i, z;

			session = p_session;
			session.register(self);
			zones = {};
			users = {};

			// fill zones with zones from session
			if (undefined !== session.user_zone) {
				zones[session.user_zone.index] = new Zone(
					session,
					session.user_zone.index,
					session.user_zone.position,
					session.zone_column_count,
					session.zone_line_count
				);
			}

			for (i = 0; i < p_session.other_zones.length; i += 1) {
				z = p_session.other_zones[i];

				zones[z.index] = new Zone(
					session,
					z.index,
					z.position,
					session.zone_column_count,
					session.zone_line_count
				);
			}
			console.log("board/initialize: zones = %s", JSON.stringify(zones));
		};


		/**
		*
		*/
		this.handle_event = function (ev) {
			var z;
			console.log("board/handle_event : " + JSON.stringify(ev));
			if (ev.type === 'join') {
				z = ev.desc.zone;
				zones[z.index] = new Zone(
					session,
					z.index,
					z.position,
					session.zone_column_count,
					session.zone_line_count
				);
			} else if (ev.type === 'leave') {
				z = ev.desc.zone;
				console.log("board/handle_event: _zones bf delete %s", JSON.stringify(zones));
				delete zones[z.index];
			} else {
				console.log("board/handle_event: unknown event");
			}
		};


		/**
		*
		*/
		this.get_zone = function (index) {
			// console.log("board/get_zone(%s) : %s", index, JSON.stringify( _zones[index] ) );
			return zones[index];
		};


		/**
		* Return the list of existing zone ids
		*/
		this.get_zone_list = function () {
			var keys = [],
				i;

			for (i in zones) {
				if (zones.hasOwnProperty(i)) {
					keys.push(parseInt(i, 10));
				}
			}
			// console.log("board/get_zone_list : %s", JSON.stringify( keys ));
			return keys;
		};


		/**
		*
		*/
		this.handle_stroke = function (stk) {
			console.log("board/handle_stroke : stroke = %s", JSON.stringify(stk));
			console.log("board/handle_stroke : zones = %s", JSON.stringify(zones));
			var z = zones[stk.zone];
			if (z) {
				z.patch_apply(stk);
			} else {
				console.warn("board/handle_stroke: trying to apply stroke for missing zone %s", stk.zone);
			}
		};


		this.handle_reset = function (session) {
			console.log("board/handle_reset");
			this.initialize(session);
		};


		this.initialize(p_session);
	}

}());

