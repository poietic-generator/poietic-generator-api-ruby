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
		slider = null;

	if (PoieticGen.Zone === undefined) {
		console.error("PoieticGen.Zone is not defined !");
	}
	if (PoieticGen.Viewer === undefined) {
		console.error("PoieticGen.Viewer is not defined !");
	}

	// instead of windows.onload
	$(document).ready(function () {
		slider = new PoieticGen.Slider("#history_slider");

		// initialize zoness
		session = new PoieticGen.ViewSession(function (session) {
			//console.log("page_draw/ready: session callback ok");
			board = new PoieticGen.Board(session);
			viewer = new PoieticGen.Viewer(session, board, 'session-viewer', null, {fullsize: true});
			//console.log("page_draw/ready: prepicker");
		}, slider);

		slider.hide();

		$("#view_start").bind("vclick", function (event) {
			event.preventDefault();
			$("#view_now").removeClass("ui-btn-active");
			$(this).addClass("ui-btn-active");
			slider.show();
			session.restart();
		});
		$("#view_now").bind("vclick", function (event) {
			event.preventDefault();
			$("#view_start").removeClass("ui-btn-active");
			$(this).addClass("ui-btn-active");
			slider.hide();
			session.current();
		});
	});

}(PoieticGen, jQuery));

