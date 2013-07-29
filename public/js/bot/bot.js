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

/*jslint browser: true*/
/*global $, jQuery, document, PoieticGen, console, alert */

(function (PoieticGen) {

	"use strict";

	if (PoieticGen.Editor === undefined) {
		alert("ERROR: PoieticGen.Editor is not defined !");
	}

	function Bot(p_editor) {

		var console = window.noconsole,
			self = this,
			editor,
			STROKE_INTERVAL = 40;

		this.name = "Bot";

		/**
		* Constructor
		*/
		this.initialize = function (editor) {
			self.editor = editor;

			setTimeout(self.draw, STROKE_INTERVAL);
		};

		this.draw = function () {
			var color, local_pos = {
				x: Math.floor(Math.random() * self.editor.column_count),
				y: Math.floor(Math.random() * self.editor.line_count)
			};

			color = Math.floor(Math.random() * 255 * 255 * 255);
			self.editor.pixel_set(local_pos, "#" + color.toString(16));

			setTimeout(self.draw, STROKE_INTERVAL);
		};

		this.initialize(p_editor);
	}

	PoieticGen.Bot = Bot;

}(PoieticGen));

