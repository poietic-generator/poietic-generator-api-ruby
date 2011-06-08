var session = null, picker;

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
            var chat = new Chat(session),
            picker = new Color.Picker({
                size: Math.floor($(window).width() / 3),
                callback: function(hex) {
                    editor.color_set( "#" + hex );
                }
            });
            $(picker.el).hide(); // hide color picker on startup
            picker.el.style.bottom = "50px";
            picker.el.style.left = "10px";

            //console.log("page_draw/ready: prepicker");
            $("#brush").click(function(event){
                event.preventDefault();
                if (true === $(picker.el).is(":hidden")) {
                    $(picker.el).show();
                    $("#brush-action").text("Hide");
                } else {
                    $(picker.el).hide();
                    $("#brush-action").text("Show");
                }
            });
        }
    );
});
