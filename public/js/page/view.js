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


/*jslint browser: true, nomen: true, continue: true */
/*global $, jQuery, document, console, PoieticGen */

(function (PoieticGen, $) {
	"use strict";

	var session = null,
		viewer = null,
		board = null,
		overlay = null,
		slider = null;

	if (PoieticGen.Zone === undefined) {
		console.error("PoieticGen.Zone is not defined !");
	}
	if (PoieticGen.Viewer === undefined) {
		console.error("PoieticGen.Viewer is not defined !");
	}

	function history_page() {
		slider.show();
		session.restart();
	}

	function view_page() {
		slider.hide();
		session.current();
	}

	function setup_buttons() {
		$("#view_start").bind("vclick", function (event) {
			event.preventDefault();
			history_page();
		});
	}

	// Set up session elements
	function setup_session() {
		var $overlay = $('#session-overlay'),
			has_overlay = ($overlay.length !== 0);

		slider = new PoieticGen.Slider("#history_slider");

		// initialize zones
		session = new PoieticGen.ViewSession(function (session) {
			board = new PoieticGen.Board(session);
			viewer = new PoieticGen.Viewer(
				session,
				board,
				'session-viewer',
				null,
				{
					fullsize: true
				}
			);
			if (has_overlay) {
				overlay = new PoieticGen.Overlay({
					session: session,
					board: board,
					overlay_id: 'session-overlay'
				});
			}
		}, slider);

		view_page();
	}

	// Load components on document ready
	$(document).ready(function () {
		setup_session();
		setup_buttons();
	});

}(PoieticGen, jQuery));

