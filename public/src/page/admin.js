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

	// instead of windows.onload
	$(document).ready(function () {
		var admin_token_parameter = /admin_token=(\w+)/.exec(location.search);

		if (admin_token_parameter !== null && admin_token_parameter.length === 2) {
			$.cookie('admin_token', admin_token_parameter[1], {path: "/"});
		}
	});

}(PoieticGen, jQuery));

