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

	function Slider(p_session, p_viewer, element) {

		var self = this,
			_slider = null,
			_timer = null,
			_viewer = p_viewer,
			_session = p_session,
			_animation_interval = 1,
			_timer_animation = null;

		this.name = "Slider";


		/**
		* Constructor
		*/
		this.initialize = function (p_session, p_viewer, element) {
			_slider = element;
			_timer = null;
			_viewer = p_viewer;
			_session = p_session;
			_session.register(self);
			_session.set_slider(self);
			_animation_interval = 1;
			_timer_animation = null;
		};


		/**
		* Change slider position
		*/
		this.set_value = function (v) {
			_slider.attr('value', v);
			_slider.slider('refresh');
		};
		
		/**
		* Get slider position
		*/
		this.value = function (v) {
			return parseInt(_slider.val());
		};

		/**
		* Set the slider range values
		*/
		this.set_range = function (min, max) {
			_slider.attr('min', min);
			_slider.attr('max', max);
			_slider.slider('refresh');
		};
		
		this.set_minimum = function (min) {
			_slider.attr('min', min);
			_slider.slider('refresh');
		};
		
		this.set_maximum = function (max) {
			_slider.attr('max', max);
			_slider.slider('refresh');
		};
		
		this.set_animation_interval = function (interval) {
			_animation_interval = interval;
		}
		
		this.start_animation = function () {
			_timer_animation = window.setTimeout(function () {
				self.set_value(self.value() + 1);
				self.start_animation();
			}, _animation_interval * 1000);
		}
		
		this.stop_animation = function () {
			if (null !== _timer_animation) {
				window.clearTimeout(_timer_animation);
				_timer_animation = null;
			}
		}


		/**
		* Handle stroke
		*/
		this.handle_stroke = function (stk) {
			window.console.log("slider/handle_stroke : stroke = " + stk.diffstamp);
			if (0 >= stk.diffstamp) {
				self.set_value(_session.last_update_timestamp());
			} else {
				var timestamp = _session.last_update_timestamp(); // not sure if this is really useful
				_timer = window.setTimeout(function () {
					self.set_value(timestamp);
				}, stk.diffstamp * 1000);
			}
		};
		
		this.update_interval = function (interval) {
			self.set_animation_interval(interval);
		}
		
		/**
		* Throw strokes
		*
		* Remove strokes not yet painted
		*/
		this.throw_strokes = function () {
			if (null !== _timer) {
				window.clearTimeout(_timer);
				_timer = null;
			}
		}

		// call constructor
		this.initialize(p_session, p_viewer, $("#history_slider"));
	}

	PoieticGen.Slider = Slider;

}(PoieticGen));

