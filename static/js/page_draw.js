var session = null;

// instead of windows.onload
$(document).ready( function() {
    // hide iphone/ipad URL bar
    setTimeout(function() { window.scrollTo(0, 1) }, 100);

    // initialize zoness
    session = new Session(
        SESSION_TYPE_DRAW,
        function() {
            //console.log("page_draw/ready: session callback ok");

            var board = new Board( session, 'session-board');
            var editor = new Editor(session, board, 'session-drawing');
            var chat = new Chat(session);

            //console.log("page_draw/ready: prepicker");
            $("#brush").click(function(event){
                event.preventDefault();
                if (true === editor.is_color_picker_visible()) {
                    editor.hide_color_picker();
                    $("#brush-action").text("Show");
                } else {
                    editor.show_color_picker();
                    $("#brush-action").text("Hide");
                }
            });
        }
    );
});
