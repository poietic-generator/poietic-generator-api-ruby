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

		var self = this,
			_slider = null,
			_animation_interval = 1,
			_timer_animation = null,
			_mouseup_handler = null;

		this.name = "Slider";


		/**
		* Constructor
		*/
		this.initialize = function (element) {
			_slider = $(element).slider();
			_animation_interval = 1;
			_timer_animation = null;
			_slider.attr('value', 0);
		};


		/**
		* Change slider position
		*/
		this.set_value = function (v) {
			v = Math.floor(v);
			window.console.log("slider/set_value : value = " + v);
			if (v >= self.minimum() && v <= self.maximum()) {
				_slider.attr('value', v);
				_slider.slider('refresh');
			}
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
			window.console.log("slider/set_range : min = " + min + " max = " + max);
			_slider.attr('min', Math.floor(min));
			_slider.attr('max', Math.floor(max));
			_slider.slider('refresh');
		};

		this.set_minimum = function (min) {
			window.console.log("slider/set_minimum : min = " + min);
			_slider.attr('min', Math.floor(min));
			_slider.slider('refresh');
		};

		this.set_maximum = function (max) {
			window.console.log("slider/set_maximum : max = " + max);
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

		this.start_animation = function () {
			self.stop_animation();

			_timer_animation = window.setTimeout(function () {
				window.console.log("slider/start_animation : value = " + self.value());
				self.set_value(self.value() + 1);
				_timer_animation = null;
				self.start_animation();
			}, _animation_interval * 1000);
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


		/**
		* Handle stroke
		*/
		this.handle_stroke = function (stk) {
			self.set_value(stk.timestamp);
		};
		
		/**
		* Handle event
		*/
		this.handle_event = function (evt) {
			if (evt.diffstamp) {
				self.set_value(evt.timestamp);
			}
		};

		// call constructor
		this.initialize(p_element);
	}

	PoieticGen.Slider = Slider;

}(PoieticGen));

