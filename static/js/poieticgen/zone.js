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
/*global window, noconsole*/

(function (window) {
	// vim: set ts=4 sw=4 et:
	"use strict";

	var ZONE_BACKGROUND_COLOR = '#000';

	function Zone(p_session, p_index, p_position, p_width, p_height) {
		var console = noconsole,
			self = this,
			_session = p_session,

			//color matrix (for maintaining state localy)
			_matrix = [],

			// patches to send
			_output_queue = [],

			// the patch we are working on
			_current_patch = null,

			// patches to apply localy
			_input_queue = [];


		// zone dimensions
		this.index = p_index;
		this.position = p_position;
		this.width = p_width;
		this.height = p_height;


		// console.log("zone/initialize width = %s", this.width );
		// console.log("zone/initialize height = %s", this.height );

		/**
		 * Set matrix default color
		 */
		this.matrix_initialize = function () {
			var imax = self.width * self.height,
				i;
			for (i = 0; i < imax; i += 1) {
				_matrix[i] = ZONE_BACKGROUND_COLOR;
			}
		};


		/*
		 * Set matrix position to given color
		 */
		this.pixel_set = function (pos, color) {
			var idx = Math.floor(pos.y) * self.width + Math.floor(pos.x);
			// console.log("zone/pixel_set idx = %s", idx );
			_matrix[idx] = color;
		};


		/*
		 * Get color at given matrix position
		 */
		this.pixel_get = function (pos) {
			var idx = Math.floor(pos.y) * self.width + Math.floor(pos.x);
			// console.log("zone/pixel_get idx = %s", idx );
			return _matrix[idx];
		};


		/*
		 * Return whethe given position is inside or outside zone
		 */
		this.contains_position = function (pos) {
			if (pos.x < 0) { return false; }
			if (pos.x >= self.width) { return false; }
			if (pos.y < 0) { return false; }
			if (pos.y >= self.height) { return false; }
			return true;
		};


		/**
		 * Create patch out of latest changes
		 */
		this.patch_record = function (pos, color) {
			var patch_update,
				patch_enqueue,
				prev_record = null;

			if (_current_patch === null) {
				// console.log("zone/patch_record: patch creation!");
				_current_patch = {
					zone: self.index,
					diff: ((new Date()) - _session.last_update_time) / 1000,
					color: color,
					changes: [ [ pos.x, pos.y, 0 ]  ]
				};
			} else {
				if (_current_patch.color !== color) {
					self.patch_enqueue();
					_current_patch = {
						zone: self.index,
						diff: (new Date()) - self._session._last_update_time,
						color: color,
						changes: [ [ pos.x, pos.y, 0 ]  ]
					};
				} else {
					// console.log("zone/patch_record: patch update!");

					// CONSTRAINT : we drop duplicate coordinates from a single patch if latest record it the same
					if (_current_patch.changes.length > 0) {
						prev_record = _current_patch.changes[_current_patch.changes.length - 1];
					}

					if ((prev_record === null) || (prev_record[0] !== pos.x)
							|| (prev_record[1] !== pos.y)) {
						_current_patch.changes.push([ pos.x, pos.y, 0 ]);
					}
				}
			}
			// console.log( "zone/patch_record: _current_patch = %s", JSON.stringify( _current_patch ) );
		};


		/**
		 * Push current patch to local patch queue
		 */
		this.patch_enqueue = function () {
			//console.log("zone/patch_enqueue: !");
			if (_current_patch !== null) {
				_output_queue.push(_current_patch);
				_session.dispatch_strokes([ _current_patch ]);
				_current_patch = null;
				console.log("zone/patch_enqueue: output queue = %s", JSON.stringify(_output_queue));
			}
		};


		/**
		 *
		 */
		this.patches_get = function () {
			var aggregate = [];

			while (_output_queue.length > 0) {
				// FIXME: compute relative time since last sync
				aggregate.push(_output_queue.shift());
			}

			return aggregate;
		};


		/**
		 * Request application for a set of patches to current zone
		 */
		this.patch_apply = function (p_patch) {
			var color = p_patch.color,
				cgset = null,
				zone_pos = null,
				i;

			for (i = 0; i < p_patch.changes.length; i += 1) {
				cgset = p_patch.changes[i];
				zone_pos = { x: cgset[0], y: cgset[1] };
				self.pixel_set(zone_pos, color);
			}
		};


		/**
		 *
		 */
		this.patches_push = function (p_patches) {
			// FIXME: call apply patch for each patches' relative time
			// FIXME : append aggregate  instead of replacing
			_input_queue = p_patches;
		};

		// constructor
		self.matrix_initialize();
	}

	window.ZONE_BACKGROUND_COLOR = ZONE_BACKGROUND_COLOR;

}(window));

