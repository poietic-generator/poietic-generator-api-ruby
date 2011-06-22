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
    sessionF = new Session(
        SESSION_TYPE_DRAW,
        function( session ) {
            //console.log("page_draw/ready: session callback ok");
            $(".username").text(session.user_name);

            var board = new Board( session );
            var editor = new Editor( session, board, 'session-editor' );
            var color_picker = new ColorPicker( editor );
            var chat = new Chat( session);
			var viewer = new Viewer( session, board, 'session-viewer', color_picker );

            //console.log("page_draw/ready: prepicker");
            $("#brush").click( function( event ){
                event.preventDefault();
                if ( true === color_picker.is_visible() ) {
                    color_picker.hide(this);
                } else {
                    color_picker.show(this);
                }
            });
        }
    );
});

