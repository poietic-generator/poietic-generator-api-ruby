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

	var OVERLAY_USER_THRESHOLD=0;

	function Overlay(p_options) {
		//var console = { log: function() {} };

		this.name = "Overlay";

		var self = this,
			session,
			board,
			overlay_id,
			overlay;


		/**
		* Constructor
		*/
		this.initialize = function (p_options) {
			// fix options if needed
			p_options = p_options || {};

			// set variables from options
			session = p_options.session || undefined;
			board = p_options.board || undefined;
			overlay_id = p_options.overlay_id || undefined;
			overlay = document.getElementById(overlay_id);

			session.register(self);

			$(window).resize(function () {
				self.update_visibility();
			});

			self.update_visibility();
		};


		/**
		* Resize canvas & various display elements
		*/
		this.update_visibility = function () {
			var win, width, height, zones, zone_idx, overlay_enabled;
			zones = board.get_zone_list();

			win = {
				w: $(window).width(),
				h : $(window).height()
			};

			// manage overlay visibility depending on :
			// - user count  (no user => disable )
			// - view type ( history=> disable)
			overlay_enabled = (
				(zones.length <= OVERLAY_USER_THRESHOLD) && 
				(session.view_type() === PoieticGen.VIEW_SESSION_TYPE_REALTIME)
			);

			if (overlay_enabled) {
				overlay.width = Math.floor(win.w);
				overlay.height = Math.floor(win.h);
				$(overlay).fadeIn('slow');
			} else {
				$(overlay).fadeOut('slow');
			}
			console.log("overlay/update_visibility : users count=" + zones.length);
		};
		

		/**
		* Handle user-related (join/leave) events
		*/
		this.handle_event = function (ev) {
			//var console = window.noconsole;

			if ((ev.type === 'join') || (ev.type === 'leave')) {
				console.log('Overlay event for ' + ev.type);
				// FIXME: read/count number of users 
				self.update_visibility();
			}
		};

		// call constructor
		this.initialize(p_options);
	}

	PoieticGen.Overlay = Overlay;

}(PoieticGen));

