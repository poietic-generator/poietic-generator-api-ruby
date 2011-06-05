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
            var drawing = new Drawing(session, 'session-drawing');
            // var globalzone = new GlobalZone(session, 'session-global');
            // var colorzone = new ColorZone(session, 'session-colors');

            //console.log("page_draw/ready: prepicker");
            $("#brush").click(function(event){
                event.preventDefault();
                if (undefined === picker) {
                    picker = new Color.Picker({
                        callback: function(hex) {
                            drawing.color_set( "#" + hex );
                        }
                    });
                    picker.el.style.top = "5px";
                    picker.el.style.left = "5px";
                }
                if (true === $(picker.el).is(":hidden")) {
                    $(picker.el).show();
                }
            });
            //console.log("page_draw/ready: postpicker");

            // create session with
        }
    );
    /*
    setInterval( function() {
    // refresh connexion to the server
    }, 10000 );
    */
});
