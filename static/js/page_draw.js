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

// instead of windows.onload
$(document).ready( function() {
    // hide iphone/ipad URL bar
    //setTimeout(function() { window.scrollTo(0, 1) }, 100);

    $(".logout").click( function ( event ) {
        if (!confirm("Leave Poietic Generator?")) {
            return false;
        }
        return true;
    });

    // initialize zoness
    sessionF = new DrawSession(
        function( session ) {
            //console.log("page_draw/ready: session callback ok");
            $(".username").text(session.user_name);

            var board = new Board( session );
            var editor = new Editor( session, board, 'session-editor' );
            //var color_picker = new ColorPicker( editor );
            var chat = new Chat( session);
			var viewer = new Viewer( session, board, 'session-viewer', editor );

            //console.log("page_draw/ready: prepicker");
            $("#brush").click( function( event ){
                event.preventDefault();
                if ( true === editor.is_color_picker_visible() ) {
                    return editor.hide_color_picker( this );
                } else {
                    return editor.show_color_picker( this );
                }
            });
        }
    );
});

