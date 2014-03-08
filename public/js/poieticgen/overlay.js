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
/*global $, jQuery, document, console, PoieticGen */

(function (PoieticGen) {
	// vim: set ts=4 sw=4 et:
	"use strict";

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
			board = p_options.board || undefined;
			overlay_id = p_options.overlay_id || undefined;
			overlay = document.getElementById(overlay_id);

			session.register(self);

			$(window).resize(function () {
				self.update_size();
			});

			self.update_size();
		};


		/**
		* Resize canvas & various display elements
		*/
		this.update_size = function () {
			var win, width, height;

			win = {
				w: $(window).width(),
				h : $(window).height()
			};

			overlay.width = Math.floor(win.w);
			overlay.height = Math.floor(win.h);
		};


		//FIXME: GYR: Add a function to handle user events
		// then enable or disable the overlay, depending on board's active zones
		

		/**
		* Handle user-related (join/leave) events
		*/
		this.handle_event = function (ev) {
			var console = window.noconsole;

			console.log("overlay/handle_event : " + JSON.stringify(ev));

			self.update_size();
		};

		// call constructor
		this.initialize(p_options);
	}

	PoieticGen.Overlay = Overlay;

}(PoieticGen));

