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

	var POSITION_TYPE_DRAWING = 0,
		POSITION_TYPE_ZONE = 0;

	// REQUIRED FOR ZONE PREFIX
	if (PoieticGen.Zone === undefined) {
		console.error("PoieticGen.Zone is not defined !");
	}

	function Viewer(p_session, p_board, p_canvas_id, p_editor, options) {
		//var console = { log: function() {} };

		options = options || {};

		var self = this,
			_session,
			_board,
			_real_canvas,
			_column_size,
			_line_size,
			_pencil_move,

			_current_zone,
			_boundaries,

			_editor = null,
			_canvas_event_fn,

			_timer_strokes = [];

		this.name = "Viewer";
		this.column_count = null;
		this.line_count = null;

		this.context = null;

		this.fullsize = options.fullsize || false;


		/**
		* Constructor
		*/
		this.initialize = function (p_session, p_board, p_canvas_id, p_editor) {
			_editor = p_editor;
			_timer_strokes = [];

			_boundaries = {
				xmin: 0,
				xmax: 0,
				ymin: 0,
				ymax: 0,
				width: 0,
				height: 0
			};

			_pencil_move = {
				enable : false
			};

			//_current_zone =  p_session.user_zone.index;
			_board = p_board;
			_session = p_session;
			_session.register(self);

			//console.log("viewer/initialize : _current_zone = " + _current_zone);

			self.update_boundaries();


			_real_canvas = document.getElementById(p_canvas_id);

			// size of editor's big pixels
			self.column_size = 1;
			self.line_size = 1;

			//var zone = _board.get_zone(_current_zone);

			self.context = _real_canvas.getContext('2d');


			$(window).resize(function () {
				self.update_size();
				self.update_paint();
			});

			self.update_size();
			self.update_paint();

			// update color picker's size for correct positionning
			if (undefined !== _editor && null !== _editor) {
				// plug some event handlers
				_real_canvas.addEventListener('mousedown', _canvas_event_fn, false);
				_real_canvas.addEventListener('touchstart', _canvas_event_fn, false);

				_real_canvas.addEventListener('mouseup', _canvas_event_fn, false);
				_real_canvas.addEventListener('touchstop', _canvas_event_fn, false);

				_real_canvas.addEventListener('mousemove', _canvas_event_fn, false);
				_real_canvas.addEventListener('touchmove', _canvas_event_fn, false);

				_editor.update_color_picker_size();
			}
		};


		/**
		* Convert local grid to canvas position
		*/
		function local_to_canvas_position(local_position) {
			return {
				x: Math.floor(local_position.x * _column_size),
				y: Math.floor(local_position.y * _line_size)
			};
		}


		/**
		* Convert canvas to local position
		*/
		function canvas_to_local_position(canvas_position) {
			return {
				x: Math.floor(canvas_position.x / _column_size),
				y: Math.floor(canvas_position.y / _line_size)
			};
		}


		/**
		* Convert local grid to zone position
		*/
		function local_to_zone_position(zone, local_position) {
			return {
				x: local_position.x - ((zone.position[0] - _boundaries.xmin) * zone.width),
				y: local_position.y - ((_boundaries.ymax - zone.position[1]) * zone.height)
			};
		}


		/**
		* Convert zone to local grid position
		*/
		function zone_to_local_position(zone, zone_position) {
			// console.log("viewer/zone_to_local_position: zone = " + JSON.stringify(zone));
			return {
				x: zone_position.x + ((zone.position[0] - _boundaries.xmin) * zone.width),
				y: zone_position.y + ((_boundaries.ymax - zone.position[1]) * zone.height)
			};
		}

		/**
		* Detect target zone given a local position
		*/
		function local_to_target_zone(local_position) {
			var result_zone,
				zones,
				zone_pos,
				zone_idx;

			zones = _board.get_zone_list();
			for (zone_idx = 0; zone_idx < zones.length; zone_idx += 1) {
				// console.log("viewer/local_to_target_zone: trying index = " + zones[zone_idx]);
				result_zone = _board.get_zone(zones[zone_idx]);
				console.log("viewer/local_to_target_zone: result_zone = " + JSON.stringify(result_zone));

				if (!result_zone) { continue; }

				zone_pos = local_to_zone_position(result_zone, local_position);
				console.log("viewer/local_to_target_zone: zone_pos = " + JSON.stringify(zone_pos));
				if (result_zone.contains_position(zone_pos)) {
					return result_zone;
				}
			}
			return null;
		}


		/**
		* Repaint zone drawing
		*/
		this.update_paint = function () {

			var console = window.console,
				remote_zone,
				zones,
				rt_zone_pos,
				local_pos,
				zone_pos,
				color,
				zone_idx,
				x,
				y;

			zones = _board.get_zone_list();
			console.log("viewer/update_paint : " + JSON.stringify(zones));

			for (zone_idx = 0; zone_idx < zones.length; zone_idx += 1) {
				remote_zone = _board.get_zone(zones[zone_idx]);
				console.log("viewer/update_paint : remote_zone = " + zone_idx);

				for (x = 0; x < remote_zone.width; x += 1) {
					for (y = 0; y < remote_zone.height; y += 1) {
						zone_pos = { 'x': x, 'y': y };
						color = remote_zone.pixel_get(zone_pos);

						local_pos = zone_to_local_position(remote_zone, zone_pos);
						self.pixel_draw(local_pos, color);
					}
				}
			}

		};


		/**
		*
		*/
		this.update_size = function () {
			var win, margin, width, height, ctx;

			win = {
				w: $(window).width(),
				h : $(window).height()
			};
			margin = 15;

			width   = this.fullsize ? win.h : win.h / 2;
			height  = this.fullsize ? win.h : win.h / 2;

			_real_canvas.width = Math.round(width) - margin;
			_real_canvas.height = Math.round(height) - margin;

			// console.log("viewer/update_size: window.width = " + [ $(window).width(), $(window).height() ]);

			// console.log("viewer/update_size: real_canvas.width = " + real_canvas.width);
			_column_size = _real_canvas.width / self.column_count;
			_line_size = _real_canvas.height / self.line_count;

			// console.log("viewer/update_size: column_size = " + _column_size);
			ctx = _real_canvas.getContext("2d");
			ctx.fillStyle = '#200';
			ctx.fillRect(0, 0, _real_canvas.width, _real_canvas.height);
		};


		/**
		* change pixel at given position, on canvas only
		*/
		this.pixel_draw = function (local_pos, color) {
			var ctx = self.context,
			//console.log("viewer/pixel_draw local_pos = " + local_pos.to_json());
				canvas_pos = local_to_canvas_position(local_pos),
				rect = {
					x : canvas_pos.x,
					y : canvas_pos.y,
					w : _column_size,
					h : _line_size
				};

			//console.log("viewer/pixel_draw rect = " + rect.to_json());
			ctx.fillStyle = PoieticGen.ZONE_BACKGROUND_COLOR;
			ctx.fillRect(rect.x, rect.y, rect.w, rect.h);

			ctx.fillStyle = color;
			ctx.fillRect(rect.x, rect.y, rect.w, rect.h);
		};


		/**
		* Handle all types on canvas events and dispatch
		*/
		_canvas_event_fn = function (event_obj) {
			var canvas = _real_canvas,
				func = self[event_obj.type];

			// FIXME verify the same formula is used with touchscreens
			event_obj.mouseX = event_obj.pageX - canvas.offsetLeft;
			event_obj.mouseY = event_obj.pageY - canvas.offsetTop;

			// FIXME: what are expected/known types ?
			if (func) { func(event_obj); }
			// console.log("clicked at " + event_obj.mouseX + "," + event_obj.mouseY);
		};


		/**
		* Handle mouse event
		*/
		this.mouseup = function (event_obj) { self.pencil_up(event_obj); };

		this.touchstop = function (event_obj) {
			var canvas = _real_canvas;
			event_obj.mouseX = event_obj.touches[0].pageX - canvas.offsetLeft;
			event_obj.mouseY = event_obj.touches[0].pageY - canvas.offsetTop;
			self.pencil_up(event_obj);
			event_obj.preventDefault();
		};

		this.pencil_up = function (event_obj) {
			_pencil_move.enable = false;
		};


		/**
		* Handle mouse event
		*/
		this.mousedown = function (event_obj) { self.pencil_down(event_obj); };

		this.touchstart = function (event_obj) {
			var canvas = _real_canvas;
			event_obj.mouseX = event_obj.touches[0].pageX - canvas.offsetLeft;
			event_obj.mouseY = event_obj.touches[0].pageY - canvas.offsetTop;
			self.pencil_down(event_obj);
			event_obj.preventDefault();
		};

		this.pencil_down = function (event_obj) {
			_pencil_move.enable = true;
			self.mousemove(event_obj);
		};



		/**
		* Handle mouse event
		*/
		this.mousemove = function (event_obj) { self.pencil_move(event_obj); };

		this.touchmove = function (event_obj) {
			var canvas = _real_canvas;
			event_obj.mouseX = event_obj.touches[0].pageX - canvas.offsetLeft;
			event_obj.mouseY = event_obj.touches[0].pageY - canvas.offsetTop;
			self.pencil_move(event_obj);
			event_obj.preventDefault();
		};

		this.pencil_move = function (event_obj) {
			var ctx = self.context,
				canvas = _real_canvas,
				canvas_pos,
				local_pos,
				target_zone,
				zone_pos,
				color;

			if (_pencil_move.enable) {
				canvas_pos = { x: event_obj.mouseX, y: event_obj.mouseY };
				local_pos = canvas_to_local_position(canvas_pos);
				target_zone = local_to_target_zone(local_pos);
				if (!target_zone) { return; }

				console.log("viewer/pencil_move: target_zone = " + JSON.stringify(target_zone));
				zone_pos = local_to_zone_position(target_zone, local_pos);

				color = _board.get_zone(target_zone.index).pixel_get(zone_pos);
				console.log("viewer/pencil_move: color = " + color);

				_editor.color_set(color);
			}
		};


		/**
		* Handle stroke 
		*
		* Draw strokes with a relative apparition time
		*/
		this.handle_stroke = function (stk) {
			window.noconsole.log("viewer/handle_stroke : stroke = " + JSON.stringify(stk));
			if (0 >= stk.diffstamp) {
				this.draw_stroke(stk);
			} else {
				_timer_strokes.push(window.setTimeout(function () {
					self.draw_stroke(stk);
				}, stk.diffstamp * 1000));
			}
		};

		/**
		* Throw strokes
		*
		* Remove strokes not yet painted
		*/
		this.throw_strokes = function () {
			while (_timer_strokes.length > 0) {
				window.clearTimeout(_timer_strokes.pop());
				window.console.log("clear");
			}
		};


		/**
		* Draw stroke
		*/
		this.draw_stroke = function (stk) {
			var console = window.noconsole,
				remote_zone,
				color,
				cgset = null,
				zone_pos = null,
				local_pos = null,
				rt_zone_pos = null,
				i;
			console.log("viewer/draw_stroke : stroke = " + JSON.stringify(stk));
			remote_zone = _board.get_zone(stk.zone);
			// console.log("viewer/handle_stroke : remote_zone = " + JSON.stringify(remote_zone));
			color = stk.color;
			// console.log("viewer/handle_stroke : color = " + JSON.stringify(color));
			for (i = 0; i < stk.changes.length; i += 1) {
				cgset = stk.changes[i];
				console.log("viewer/draw_stroke : cgset = " + JSON.stringify(cgset));
				zone_pos = { x: cgset[0], y: cgset[1] };
				console.log("viewer/draw_stroke : zone_pos = " + JSON.stringify(zone_pos));
				local_pos = zone_to_local_position(remote_zone, zone_pos);
				console.log("viewer/draw_stroke : local_pos = " + JSON.stringify(local_pos));
				self.pixel_draw(local_pos, color);
			}
		};


		/**
		* Handle user-related (join/leave) events
		*/
		this.handle_event = function (ev) {
			var console = window.noconsole,
				zones,
				remote_zone,
				x,
				y,
				w,
				h;

			console.log("viewer/handle_event : " + JSON.stringify(ev));

			self.update_boundaries();
			self.update_size();
			self.update_paint();
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
					if (y > _boundaries.ymay) { _boundaries.ymay = y; }
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

			console.log("viewer/update_boundaries : boundaries = " + JSON.stringify(_boundaries));
			self.column_count = _boundaries.width * _session.zone_column_count;
			self.line_count = _boundaries.height * _session.zone_line_count;
		};

		// call constructor
		this.initialize(p_session, p_board, p_canvas_id, p_editor);
	}

	PoieticGen.Viewer = Viewer;

}(PoieticGen));

