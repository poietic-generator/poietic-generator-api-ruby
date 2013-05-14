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

/*jslint browser: true, nomen: true, continue: true */
/*global $, jQuery, document, console, ColorPicker, PoieticGen */

(function (PoieticGen) {
	"use strict";

	var EDITOR_GRID_COLOR = '#444',
		EDITOR_GRID_WIDTH = 0.5,
		EDITOR_BOUNDARIES_COLOR = '#888',
		EDITOR_BOUNDARIES_WIDTH = 2,
		EDITOR_BORDER_RATIO = 0,

		POSITION_TYPE_DRAWING = 0,
		POSITION_TYPE_ZONE = 0;

	// REQUIRED FOR ZONE PREFIX
	if (PoieticGen.Zone === undefined) {
		console.error("PoieticGen.Zone is not defined !");
	}

	if (PoieticGen.Patch === undefined) {
		console.error("PoieticGen.Patch is not defined !");
	}

	function Editor(p_session, p_board, p_canvas_id) {
		var console = window.noconsole,
		//var console = { log: function() {} };

			self = this,
			_session,
			_enqueue_timer,
			_board,
			_color,
			_pencil_move = { enable : false },
			_real_canvas,
			_grid_canvas,
			_column_size,
			_line_size,

			_current_zone,
			_canvas_event_fn,
			_color_picker;

		this.name = "Editor";
		this.column_count = null;
		this.line_count = null;
		this.border_column_count = null;
		this.border_line_count = null;

		this.context = null;


		/**
		* Constructor
		*/
		this.initialize = function (p_session, p_board, p_canvas_id) {

			_current_zone =  p_session.user_zone.index;
			console.log("editor/initialize : _current_zone = " + _current_zone);
			_board = p_board;
			_color = '#f00';

			_color_picker = new ColorPicker(this);

			_pencil_move = {
				enable : false
			};

			_session = p_session;
			_session.register(self);

			self.column_count = p_session.zone_column_count;
			self.line_count = p_session.zone_line_count;
			self.border_column_count = EDITOR_BORDER_RATIO * p_session.zone_column_count;
			self.border_line_count = EDITOR_BORDER_RATIO * p_session.zone_column_count;

			_real_canvas = document.getElementById(p_canvas_id);
			_grid_canvas = null;

			// size of editor's big pixels

			var zone = _board.get_zone(_current_zone);
			_enqueue_timer = window.setInterval(zone.patch_enqueue, PoieticGen.PATCH_LIFESPAN);

			self.context = _real_canvas.getContext('2d');

			// plug some event handlers
			_real_canvas.addEventListener('mousedown', _canvas_event_fn, false);
			_real_canvas.addEventListener('touchstart', _canvas_event_fn, false);

			_real_canvas.addEventListener('mouseup', _canvas_event_fn, false);
			_real_canvas.addEventListener('touchstop', _canvas_event_fn, false);

			_real_canvas.addEventListener('mousemove', _canvas_event_fn, false);
			_real_canvas.addEventListener('touchmove', _canvas_event_fn, false);

			$(window).resize(function () {
				self.update_size();
				self.update_paint();
			});

			self.update_size();
			self.update_paint();
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
		function local_to_zone_position(local_position) {
			return {
				x: local_position.x - self.border_column_count,
				y: local_position.y - self.border_line_count
			};
		}


		/**
		* Convert zone to local grid position
		*/
		function zone_to_local_position(zone_position) {
			return {
				x: zone_position.x + self.border_column_count,
				y: zone_position.y + self.border_line_count
			};
		}


		/**
		* Get relative zone position
		*/
		function zone_relative_position(remote_zone, remote_zone_position) {
			// console.log("editor/zone_relative_position : remote_zone = " + JSON.stringify( remote_zone ));
			// console.log("editor/zone_relative_position : remote_zone_position = " + JSON.stringify( remote_zone_position ));

			var dx, dy, edx, edy, res;

			dx = remote_zone.position[0] - _board.get_zone(_current_zone).position[0];
			// y coordinates are inverted, because of the canvas ...
			dy = _board.get_zone(_current_zone).position[1] - remote_zone.position[1];
			// console.log("editor/zone_relative_position : " + JSON.stringify({ dx: dx, dy: dy }));
			edx = dx * self.column_count;
			edy = dy * self.line_count;

			// console.log("editor/zone_relative_position : " + JSON.stringify({ edx: edx, edy: edy }));

			res = {
				x : edx + remote_zone_position.x,
				y : edy + remote_zone_position.y
			};

			// console.log("editor/zone_relative_position : result = " + JSON.stringify( res ));
			return res;
		}


		/*
		* draw zone grid
		*/
		this.draw_grid = function () {
			// apply grid canvas on the real canvas
			var grid_ctx,
				canvas,
				w_max,
				w,
				h_max,
				h,
				local_pos,
				canvas_pos,
				local_tl,
				canvas_tl,
				ctx = self.context;

			// create grid if none exist
			if (self.grid_canvas === null) {
				self.grid_canvas = document.createElement('canvas');
				self.grid_canvas.width = _real_canvas.width;
				self.grid_canvas.height = _real_canvas.height;
				canvas = self.grid_canvas;
				grid_ctx = canvas.getContext("2d");

				//console.log("editor/draw_grid: before lines");

				w_max = self.column_count + (2 * self.border_column_count);
				for (w = 0; w <= w_max; w += 1) {
					local_pos = { 'x': w, 'y': 0 };
					canvas_pos = local_to_canvas_position(local_pos);

					grid_ctx.moveTo(canvas_pos.x, 0);
					grid_ctx.lineTo(canvas_pos.x, canvas.height);
				}

				h_max = self.line_count + (2 * self.border_line_count);
				for (h = 0; h <= h_max; h += 1) {
					local_pos = { 'x': 0, 'y': h };
					canvas_pos = local_to_canvas_position(local_pos);
					grid_ctx.moveTo(0, canvas_pos.y);
					grid_ctx.lineTo(canvas.width, canvas_pos.y);
				}
				grid_ctx.lineWidth = EDITOR_GRID_WIDTH;
				grid_ctx.strokeStyle = EDITOR_GRID_COLOR;
				grid_ctx.stroke();

				grid_ctx.beginPath();
				local_tl = {
					x : self.border_column_count,
					y : self.border_line_count
				};
				canvas_tl =  local_to_canvas_position(local_tl);
				canvas_tl.w = Math.floor(self.column_count * _column_size);
				canvas_tl.h = Math.floor(self.line_count * _line_size);

				grid_ctx.lineWidth = EDITOR_BOUNDARIES_WIDTH;
				grid_ctx.strokeStyle = EDITOR_BOUNDARIES_COLOR;
				grid_ctx.strokeRect(canvas_tl.x, canvas_tl.y, canvas_tl.w, canvas_tl.h);
			}
			ctx.drawImage(self.grid_canvas, 0, 0);
		};


		/**
		* Repaint zone drawing
		*/
		this.update_paint = function () {

			var remote_zone,
				zones,
				rt_zone_pos,
				local_pos,
				zone_pos,
				zone_idx,
				x,
				y,
				color;

			zones = _board.get_zone_list();
			console.log("editor/update_paint : " + JSON.stringify(zones));

			for (zone_idx = 0; zone_idx < zones.length; zone_idx += 1) {
				remote_zone = _board.get_zone(zones[zone_idx]);
				if (!remote_zone) { continue; }
				console.log("editor/update_paint : remote_zone = " + zone_idx);

				for (x = 0; x < self.column_count; x += 1) {
					for (y = 0; y < self.line_count; y += 1) {
						zone_pos = { 'x': x, 'y': y };
						color = remote_zone.pixel_get(zone_pos);

						rt_zone_pos = zone_relative_position(remote_zone, zone_pos);
						local_pos = zone_to_local_position(rt_zone_pos);
						self.pixel_draw(local_pos, color);
					}
				}
			}

		};


		/**
		*
		*/
		this.update_size = function () {
			var real_canvas, win, margin, ctx;

			real_canvas = _real_canvas;
			win = {
				w: $(window).width(),
				h : $(window).height()
			};
			margin = 15;

			real_canvas.width = Math.round(win.h / 2) - margin;
			real_canvas.height = Math.round(win.h / 2) - margin;

			// console.log("editor/update_size: window.width = " + [ $(window).width(), $(window).height() ] );

			// console.log("editor/update_size: real_canvas.width = " + real_canvas.width);
			_column_size = real_canvas.width / (self.column_count + (self.border_column_count * 2));
			_line_size = real_canvas.height / (self.line_count + (self.border_line_count * 2));

			// console.log("editor/update_size: column_size = " + _column_size);

			self.grid_canvas = null;

			ctx = real_canvas.getContext("2d");
			ctx.fillStyle = '#000';
			ctx.fillRect(0, 0, real_canvas.width, real_canvas.height);

			self.draw_grid();
			this.update_color_picker_size();
		};

		/**
		* Handle mouse event
		*/
		this.mouseup = function (event_obj) { self.pencil_up(event_obj); };

		this.touchstop = function (event_obj) {
			event_obj.mouseX = event_obj.touches[0].pageX - _real_canvas.offsetLeft;
			event_obj.mouseY = event_obj.touches[0].pageY - _real_canvas.offsetTop;
			self.pencil_up(event_obj);
		};

		this.pencil_up = function (event_obj) {
			_pencil_move.enable = false;
		};


		/**
		* Handle mouse event
		*/
		this.mousedown = function (event_obj) { self.pencil_down(event_obj); };

		this.touchstart = function (event_obj) {
			event_obj.mouseX = event_obj.touches[0].pageX - _real_canvas.offsetLeft;
			event_obj.mouseY = event_obj.touches[0].pageY - _real_canvas.offsetTop;
			self.pencil_down(event_obj);
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
			event_obj.mouseX = event_obj.touches[0].pageX - _real_canvas.offsetLeft;
			event_obj.mouseY = event_obj.touches[0].pageY - _real_canvas.offsetTop;
			self.pencil_move(event_obj);
		};

		this.pencil_move = function (event_obj) {
			var ctx = self.context,
				canvas_pos,
				local_pos,
				zone_pos,
				bound,
			    canvas = _real_canvas;

			if (_pencil_move.enable) {
				canvas_pos = { x: event_obj.mouseX, y: event_obj.mouseY };
				local_pos = canvas_to_local_position(canvas_pos);
				zone_pos = local_to_zone_position(local_pos);

				bound = _board.get_zone(_current_zone).contains_position(zone_pos);

				if (bound) {
					self.pixel_set(local_pos, _color);
				}
				// else {
				//FIXME: _color = _board.get_zone(_current_zone).pixel_get( zone_pos );
				// }
			}
		};


		/**
		* change pixel at given position, on canvas only
		*/
		this.pixel_draw = function (local_pos, color) {
			var ctx = self.context,
			//console.log("editor/pixel_draw local_pos = " + local_pos.to_json() );
			    canvas_pos = local_to_canvas_position(local_pos),
			    rect = {
					x : canvas_pos.x + (0.1 * _column_size),
					y : canvas_pos.y + (0.1 * _column_size),
					w : _column_size - (0.2 * _column_size),
					h : _line_size - (0.2 * _column_size)
				};
			//console.log("editor/pixel_draw rect = " + rect.to_json() );

			ctx.fillStyle = PoieticGen.ZONE_BACKGROUND_COLOR;
			ctx.fillRect(rect.x, rect.y, rect.w, rect.h);

			ctx.fillStyle = color;
			ctx.fillRect(rect.x, rect.y, rect.w, rect.h);
		};


		/*
		* Set pixel at given position to given color
		*/
		this.pixel_set = function (local_pos, color) {
			var zone_pos;

			zone_pos = local_to_zone_position(local_pos);
			//console.log( "editor/pixel_set: zone_pos = " + zone_pos.to_json() );
			// record to zone
			_board.get_zone(_current_zone).pixel_set(zone_pos, color);
			// add to patch structure
			_board.get_zone(_current_zone).patch_record(zone_pos, color);
			// draw localy
			self.pixel_draw(local_pos, color);
		};


		/**
		* Pick color of pixel
		*/
		this.pixel_get = function (local_pos) {
			//FIXME: detect bound zone...
			//_return zone.pixel_get( pos );
		};


		/**
		* Change color
		*/

		this.color_set = function (hexcolor) {
			_color = hexcolor;
			// FIXME:
			console.log("editor/color_set: requestion patch enqueue");
			_board.get_zone(_current_zone).patch_enqueue();
			$("#current_color").css("background-color",  _color);
		};


		/**
		* Handle all types on canvas events and dispatch
		*/
		_canvas_event_fn = function (event_obj) {
			var canvas = _real_canvas,
				is_func;

			// FIXME verify the same formula is used with touchscreens
			event_obj.mouseX = event_obj.pageX - canvas.offsetLeft;
			event_obj.mouseY = event_obj.pageY - canvas.offsetTop;

			is_func = self[event_obj.type];
			if (is_func) { is_func(event_obj); }
			event_obj.preventDefault();
			// console.log("clicked at " + event_obj.mouseX + "," + event_obj.mouseY );
		};


		/**
		*
		*/
		this.handle_stroke = function (stk) {
			// console.log("editor/handle_stroke : stroke = " + JSON.stringify( stk ));
			var remote_zone = _board.get_zone(stk.zone),
			// console.log("editor/handle_stroke : remote_zone = " + JSON.stringify( remote_zone ));
			    color = stk.color,
			// console.log("editor/handle_stroke : color = " + JSON.stringify( color ));
			    cgset = null,
			    zone_pos = null,
			    local_pos = null,
			    rt_zone_pos = null,
				i;

			for (i = 0; i < stk.changes.length; i += 1) {
				cgset = stk.changes[i];
				// console.log("editor/handle_stroke : cgset = " + JSON.stringify( cgset ));
				zone_pos = { x: cgset[0], y: cgset[1] };
				// console.log("editor/handle_stroke : zone_pos = " + JSON.stringify( zone_pos ));
				rt_zone_pos = zone_relative_position(remote_zone, zone_pos);
				// console.log("editor/handle_stroke : rt_zone_pos = " + JSON.stringify( rt_zone_pos ));

				local_pos = zone_to_local_position(rt_zone_pos);
				// console.log("editor/handle_stroke : local_pos = " + JSON.stringify( local_pos ));
				self.pixel_draw(local_pos, color);
			}
		};


		/**
		* Get patches generated by the drawing
		*/
		this.get_strokes = function () {
			var strokes = _board.get_zone(_current_zone).patches_get();
			console.log("editor/get_strokes: strokes = " + JSON.stringify(strokes));
			return strokes;
		};


		this.update_color_picker_size = function () {
			_color_picker.update_size(_real_canvas);
		};


		this.hide_color_picker = function (p_link) {
			_color_picker.hide();
			$(p_link).removeClass("ui-btn-active");
			return false;
		};

		this.is_color_picker_visible = function () {
			return _color_picker.is_visible();
		};

		this.show_color_picker = function (p_link) {
			_color_picker.show();
			$(p_link).addClass("ui-btn-active");
			return true;
		};

		// call constructor
		this.initialize(p_session, p_board, p_canvas_id);
	}

	PoieticGen.Editor = Editor;

}(PoieticGen));

