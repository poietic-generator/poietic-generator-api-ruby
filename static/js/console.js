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
/*global document, console */

(function () {
	// vim: set ts=4 sw=4 et:
	"use strict";

	var names = ["log", "debug", "info", "warn",
		"error", "assert", "dir", "dirxml",
		"group", "groupEnd", "time", "timeEnd",
		"count", "trace", "profile", "profileEnd"],
		i, len, nulfn;

	window.noconsole = {};
	nulfn = function () {};

	for (i = 0, len = names.length; i < len; i += 1) {
		window.noconsole[names[i]] = nulfn;
	}

	if (!(window.hasOwnProperty("console"))) {
		window.console = window.noconsole;
	}

}());
