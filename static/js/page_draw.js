var session = null;

// instead of windows.onload 
$(document).ready( function() {

    // hide iphone/ipad URL bar
    setTimeout(function() { window.scrollTo(0, 1) }, 100);

    // initialize zoness
    session = new Session(function() {
	drawzone = new DrawZone(session, 'session-drawzone');
	globalzone = new GlobalZone(session, 'session-global');
	colorzone = new ColorZone(session, 'session-colors');
	// create session with 
    } );

    /*
    setInterval( function() {
	// refresh connexion to the server
    }, 10000 );
    */
} );
