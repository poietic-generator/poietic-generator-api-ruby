/******************************************************************************/
/*                                                                            */
/*  Poetic Generator Reloaded is a multiplayer and collaborative art          */
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

/*jslint browser: true, nomen: true*/
/*global $, jQuery, document, PoieticGen, console, alert */

(function (PoieticGen) {

	"use strict";

	if (PoieticGen.Editor === undefined) {
		alert("ERROR: PoieticGen.Editor is not defined !");
	}

	function Bot(p_editor) {

		var console = window.noconsole,
			self = this,
			_editor = null,
			_base_hue = 0,
			_started = false,
			_timer = null,
			_str_pad_number = null,
			_rgb_to_hex = null,
			_hsv_to_rgb = null,
			INTERVAL_AGRESSIVE = 40,
			INTERVAL_STANDARD = 500,
			INTERVAL_KIND = 1500,
			STROKE_INTERVAL = INTERVAL_STANDARD;

		this.name = "Bot";

		/**
		 * Returns the 'str_number' string in parameter
		 * left-padded with 'len' zeros.
		 */
		_str_pad_number = function (str_number, len) {
			var padd_len = len - str_number.length;
			if (padd_len > 0) {
				return [padd_len + 1].join('0') + str_number;
			}
			return str_number;
		};

		_rgb_to_hex = function (r, g, b) {
			return _str_pad_number(r.toString(16), 2) +
				_str_pad_number(g.toString(16), 2) +
				_str_pad_number(b.toString(16), 2);
		};

		/**
		 * HSV to RGB color conversion
		 *
		 * H runs from 0 to 360 degrees
		 * S and V run from 0 to 100
		 *
		 * Ported by Roshambo from the excellent java algorithm by Eugene Vishnevsky at:
		 * http://www.cs.rit.edu/~ncs/color/t_convert.html
		 */
		_hsv_to_rgb = function (h, s, v) {
			var r, g, b, i, f, p, q, t;

			// Make sure our arguments stay in-range
			h = Math.max(0, Math.min(360, h));
			s = Math.max(0, Math.min(100, s));
			v = Math.max(0, Math.min(100, v));

			// We accept saturation and value arguments from 0 to 100 because that's
			// how Photoshop represents those values. Internally, however, the
			// saturation and value are calculated from a range of 0 to 1. We make
			// That conversion here.
			s /= 100;
			v /= 100;

			if (s === 0) {
				// Achromatic (grey)
				r = g = b = v;
				return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
			}

			h /= 60; // sector 0 to 5
			i = Math.floor(h);
			f = h - i; // factorial part of h
			p = v * (1 - s);
			q = v * (1 - s * f);
			t = v * (1 - s * (1 - f));

			switch (i) {
			case 0:
				r = v;
				g = t;
				b = p;
				break;
			case 1:
				r = q;
				g = v;
				b = p;
				break;
			case 2:
				r = p;
				g = v;
				b = t;
				break;
			case 3:
				r = p;
				g = q;
				b = v;
				break;
			case 4:
				r = t;
				g = p;
				b = v;
				break;
			default: // case 5:
				r = v;
				g = p;
				b = q;
			}

			return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
		};

		/**
		* Constructor
		*/
		this.initialize = function (editor) {
			_editor = editor;
			_base_hue = Math.floor(Math.random() * 360);
		};

		this.draw = function () {
			var rgb, local_pos = {
				x: Math.floor(Math.random() * _editor.column_count),
				y: Math.floor(Math.random() * _editor.line_count)
			};

			_started = true;

			rgb = _hsv_to_rgb(_base_hue, 80, Math.random() * 100);
			console.log("color: #" + _rgb_to_hex(rgb[0], rgb[1], rgb[2]));
			_editor.pixel_set(local_pos, "#" + _rgb_to_hex(rgb[0], rgb[1], rgb[2]));

			_timer = window.setTimeout(self.draw, STROKE_INTERVAL);
		};

		this.stop = function () {
			if (null !== _timer) {
				window.clearTimeout(_timer);
				_timer = null;
			}
			_started = false;
		};

		this.started = function () {
			return _started;
		};

		this.initialize(p_editor);
	}

	PoieticGen.Bot = Bot;

}(PoieticGen));

