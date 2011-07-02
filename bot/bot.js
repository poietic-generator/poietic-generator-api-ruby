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

var BASE_URL = "http://localhost:9393/";

phantom.click = function ( el ) {
	var evt = document.createEvent('MouseEvents');
	evt.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0,
			false, false, false, false, 0, null);
	el.dispatchEvent(evt);
}

if (phantom.state.length === 0) {
	console.log("Setting up Phantom...");
	var r = Math.floor( Math.random() * 256 ).toString(16);
	var g = Math.floor( Math.random() * 256 ).toString(16);
	var b = Math.floor( Math.random() * 256 ).toString(16);
	phantom.state = "#" + r + g + b;

	phantom.open( BASE_URL );

} else {
	console.log( "[color] " + phantom.state );
	console.log( "[url] " + document.location.href );

	if ( document.location.href == BASE_URL ) {
		// on base url
		// set username (bot + date)
		// set logout date
		// validate
		var username_elem = document.getElementById('username');
		var play_elem = document.getElementById('link_play');
		username_elem.value = "bot_" + phantom.state;

		phantom.click( play_elem );


	} else if ( document.location.href.match( /\/page\/draw$/ ) ) {
		// on drawing page
		// set color
		// generate a random number of strokes in editor
		//   set a direction
		//   continue in that direction
		//var editor = document.getElementById('session-editor');
		// console.log( "  [canvas] width" + canvas_elem.width );
		// console.log( document.body.innerHTML );
		//editor.color_set( phantom.state );

		var stroke = function() {
			var local_pos = { 
				x: Math.floor( Math.random() * editor.column_count ),
				y: Math.floor( Math.random() * editor.line_count )
			};

			is_black = ( Math.floor( Math.random() * 20 ) > 10 ) ;
			if (is_black) {
				editor.pixel_set( local_pos, "#000" );
			} else {
				editor.pixel_set( local_pos, phantom.state );
			}
			setTimeout( stroke, 100 );
		}
		setTimeout( stroke, 100 );

	} else {
		console.log("  [oops] unknown page");
		phantom.exit();
	}

}
