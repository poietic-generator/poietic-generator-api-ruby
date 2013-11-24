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

	function Slider(p_element) {

		var console = window.noconsole,
			self = this,
			_slider = null,
			_animation_interval = 1,
			_timer_animation = null,
			_mouseup_handler = null,
			_animate = null,
			_cursor_moved_by_user = false,
			_catch_mouse = null;

		this.name = "Slider";


		/**
		* Constructor
		*/
		this.initialize = function (element) {
			_slider = $(element).slider();
			_animation_interval = 1;
			_timer_animation = null;
			_slider.attr('value', 0);
			_catch_mouse();
		};


		/**
		* Change slider position
		*/
		this.set_value = function (v) {
			if (_cursor_moved_by_user === true) {
				return;
			}
			v = Math.floor(v);
			console.log("slider/set_value : value = " + v);
			_slider.attr('value', v);
			_slider.slider('refresh');
		};

		/**
		* Get slider position
		*/
		this.value = function (v) {
			return parseInt(_slider.val(), 10);
		};

		/**
		* Set the slider range values
		*/
		this.set_range = function (min, max) {
			console.log("slider/set_range : min = " + min + " max = " + max);
			_slider.attr('min', Math.floor(min));
			_slider.attr('max', Math.floor(max));
			_slider.slider('refresh');
		};

		this.set_minimum = function (min) {
			console.log("slider/set_minimum : min = " + min);
			_slider.attr('min', Math.floor(min));
			_slider.slider('refresh');
		};

		this.set_maximum = function (max) {
			console.log("slider/set_maximum : max = " + max);
			_slider.attr('max', Math.floor(max));
			_slider.slider('refresh');
		};

		this.minimum = function () {
			return parseInt(_slider.attr('min'), 10);
		};

		this.maximum = function () {
			return parseInt(_slider.attr('max'), 10);
		};

		this.set_animation_interval = function (interval) {
			_animation_interval = interval;
		};

		/**
		 * Animate the slider button with interval
		 */
		this.start_animation = function () {
			self.stop_animation();

			_animate((new Date()).getTime());
		};

		_animate = function (init_stamp) {
			self.set_value(self.value() + 1);

			_timer_animation = window.setTimeout(function () {
				if (_timer_animation) {
					_animate(init_stamp + 1000);
				}
			}, (_animation_interval * 1000) - ((new Date()).getTime() - init_stamp));
		};

		this.stop_animation = function () {
			if (null !== _timer_animation) {
				window.clearTimeout(_timer_animation);
				_timer_animation = null;
			}
		};

		this.show = function () {
			$(".slider").show();
		};

		this.hide = function () {
			$(".slider").hide();
		};

		this.mouseup = function (callback) {
			$(".ui-slider").bind("vmouseup", callback);
		};

		_catch_mouse = function () {
			$(".ui-slider").bind("vmouseup", function () {
				_cursor_moved_by_user = false;
			});
			$(".ui-slider").bind("vmousedown", function () {
				_cursor_moved_by_user = true;
			});
		};

		// call constructor
		this.initialize(p_element);
	}

	PoieticGen.Slider = Slider;

}(PoieticGen));
