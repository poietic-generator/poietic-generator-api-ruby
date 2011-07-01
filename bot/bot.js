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

// use phantomjs

var BASE_URL = "http://localhost:9393";

if (phantom.state.length === 0) {
	console.log("Setting up Phantom...");

	phantom.open( BASE_URL );

} else {

	if ( document.location.href == BASE_URL ) {
		// on base url
		// set username (bot + date)
		// set logout date
		// validate

		// on drawing page
		// pick a color
		// generate a random number of strokes in editor
		//   set a direction
		//   continue in that direction
	} else {
		console.log("  [oops] unknown page");
		phantom.exit();
	}

}
