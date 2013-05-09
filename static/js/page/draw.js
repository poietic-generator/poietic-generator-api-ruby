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
/*global $, jQuery, document, confirm, console, ColorPicker, DrawSession, Board, Editor, Chat, Viewer */


(function (window) {
	"use strict";

	var session = null,
		viewer = null,
		board = null,
		editor = null,
		chat = null;

	// instead of windows.onload
	$(document).ready(function () {
		$(".logout").bind("click", function (event) {
			if (!confirm("Leave Poietic Generator?")) {
				return false;
			}
			return true;
		});

		// initialize zoness
		session = new DrawSession(
			function (session) {
				//console.log("page_draw/ready: session callback ok");
				$(".username").text(session.user_name);

				board = new Board(session);
				editor = new Editor(session, board, 'session-editor');
				//var color_picker = new ColorPicker( editor );
				chat = new Chat(session);
				viewer = new Viewer(session, board, 'session-viewer', editor);

				//console.log("page_draw/ready: prepicker");
				$("#brush").bind("vclick", function (event) {
					var result;
					event.preventDefault();
					if (true === editor.is_color_picker_visible()) {
						result = editor.hide_color_picker(this);
					} else {
						result = editor.show_color_picker(this);
					}
					return result;
				});

				$("#canvas-container").bind("vclick", function (event) {
					if (true === editor.is_color_picker_visible()) {
						editor.hide_color_picker($("#brush"));
					}
				});
			}
		);
	});

}());
