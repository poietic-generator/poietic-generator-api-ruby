var session = null;

// instead of windows.onload
$(document).ready( function() {
    // hide iphone/ipad URL bar
    setTimeout(function() { window.scrollTo(0, 1) }, 100);

    // initialize zoness
    sessionF = new Session(
        SESSION_TYPE_DRAW,
        function( session ) {
            //console.log("page_draw/ready: session callback ok");
            $(".username").text(session.user_name);

            var board = new Board( session );
            var editor = new Editor( session, board, 'session-editor' );
            var chat = new Chat( session);
			var viewer = new Viewer( session, board, 'session-viewer' );

            //console.log("page_draw/ready: prepicker");
            $("#brush").click( function( event ){
                event.preventDefault();
                if ( true === editor.is_color_picker_visible() ) {
                    editor.hide_color_picker();
                } else {
                    editor.show_color_picker();
                }
            });
        }
    );
});

