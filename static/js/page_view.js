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

var session = null;
var viewer = null;
var board = null;

// instead of windows.onload
$(document).ready( function() {
    // hide iphone/ipad URL bar
    //setTimeout(function() { window.scrollTo(0, 1) }, 100);

    // initialize zoness
    session = new ViewSession(
        function( session ) {
            //console.log("page_draw/ready: session callback ok");
            board = new Board( session );
			viewer = new Viewer( session, board, 'session-viewer', color_picker );
            //console.log("page_draw/ready: prepicker");
        }
    );
});

