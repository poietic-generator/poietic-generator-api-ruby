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

/*jslint browser: true, nomen: true, continue: true */
/*global $, jQuery, document, console */

(function ($) {
	"use strict";

	function setUsernameCookie() {
		$.cookie(
			"user_name",
			$("#credentials").find("input#username").val(),
			{path: "/"}
		);
	}

	$(document).ready(function () {
		var user_name = $.cookie('user_name');
		if (user_name) {
			$("#username").val(user_name);
		}

		$("#credentials").submit(function (event) {
			event.preventDefault();
			setUsernameCookie();
			document.location = $(this).attr("action");
		});

		$("#link_play").bind("vclick", function (event) {
			setUsernameCookie();
			return true;
		});
	});

}(jQuery));
