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

/*jslint browser: true, nomen: true, continue: true*/
/*global $, jQuery, document, console, PoieticGen */

(function (PoieticGen) {
	// vim: set ts=4 sw=4 et:
	"use strict";

	// REQUIRED FOR ZONE PREFIX
	if (PoieticGen.Zone === undefined) {
		console.error("PoieticGen.Zone is not defined !");
	}

	function Overlay(p_session, p_board, p_canvas_id, options) {
		//var console = { log: function() {} };

		options = options || {};

		var self = this,
			_session,
			_board,
			_real_canvas,
			_real_overlay,
			_boundaries;

		this.name = "Overlay";
		this.column_count = null;
		this.line_count = null;

		this.fullsize = options.fullsize || false;
		this.overlay = options.overlay || false;
		this.overlay_id = options.overlay_id || undefined;


		/**
		* Constructor
		*/
		this.initialize = function (p_session, p_board, p_canvas_id) {

			_boundaries = {
				xmin: 0,
				xmax: 0,
				ymin: 0,
				ymax: 0,
				width: 0,
				height: 0
			};

			_board = p_board;
			_session = p_session;
			_session.register(self);

			self.update_boundaries();

			_real_canvas = document.getElementById(p_canvas_id);
			if (self.overlay) {
				_real_overlay = document.getElementById(self.overlay_id);
			}

			$(window).resize(function () {
				self.update_size();
			});

			self.update_size();
		};


		/**
		* Resize canvas & various display elements
		*/
		this.update_size = function () {
			var win, width, height, ctx, canvas, next, minsize;

			win = {
				w: $(window).width(),
				h : $(window).height()
			};

			_real_overlay.width = Math.floor(win.w);
			_real_overlay.height = Math.floor(win.h);

			console.log("overlay/update_size: window.width = " + [ $(window).width(), $(window).height() ]);
		};


		//FIXME: GYR: Add a function to handle user events
		// then enable or disable the overlay, depending on board's active zones
		

		/**
		* Handle user-related (join/leave) events
		*/
		this.handle_event = function (ev) {
			var console = window.noconsole;

			console.log("overlay/handle_event : " + JSON.stringify(ev));

			self.update_boundaries();
			self.update_size();
		};


		/**
		* Update boundaries from board information
		*/
		this.update_boundaries = function () {
			var console = window.noconsole,
				zones,
				remote_zone,
				x,
				y,
				zone_idx;

			zones = _board.get_zone_list();

			// reset boundaries first
			_boundaries = { xmin: 0, xmax: 0, ymin: 0, ymax: 0, width: 0, height: 0 };

			for (zone_idx = 0; zone_idx < zones.length; zone_idx += 1) {
				remote_zone = _board.get_zone(zones[zone_idx]);
				if (remote_zone !== null) {
					x = remote_zone.position[0];
					y = remote_zone.position[1];
					if (x < _boundaries.xmin) { _boundaries.xmin = x; }
					if (x > _boundaries.xmax) { _boundaries.xmax = x; }
					if (y < _boundaries.ymin) { _boundaries.ymin = y; }
					if (y > _boundaries.ymax) { _boundaries.ymax = y; }
				}
			}

			// we make a square now ^^
			_boundaries.width = _boundaries.xmax - _boundaries.xmin;
			_boundaries.height = _boundaries.ymax - _boundaries.ymin;

			if (_boundaries.width > _boundaries.height) {
				_boundaries.ymax = _boundaries.ymin + _boundaries.width;
				_boundaries.width = _boundaries.width + 1;
				_boundaries.height = _boundaries.width;
			} else {
				_boundaries.xmax = _boundaries.xmin + _boundaries.height;
				_boundaries.height = _boundaries.height + 1;
				_boundaries.width = _boundaries.height;
			}

			console.log("overlay/update_boundaries : boundaries = " + JSON.stringify(_boundaries));
			self.column_count = _boundaries.width * _session.zone_column_count;
			self.line_count = _boundaries.height * _session.zone_line_count;
		};

		// call constructor
		this.initialize(p_session, p_board, p_canvas_id);
	}

	PoieticGen.Overlay = Overlay;

}(PoieticGen));

