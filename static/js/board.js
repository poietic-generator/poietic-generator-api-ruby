

/**
 * Global view
 */
function Board( p_session, p_canvas_id ) {
    
    var self = this;

    var _real_canvas;
    var _context;
    var _zones;

    this.initialize = function( p_session, p_canvas_id ) {

        _real_canvas = document.getElementById( p_canvas_id );
        _context = _real_canvas.getContext('2d');

        // plug some event handlers
        $(window).resize(function() {
            self.update_size();
            self.update_paint();
        });

        self.update_size();
        self.update_paint();
    }


    /**
     * Update drawing size according to viewport
     */
    this.update_size = function() {
	// FIXME: not implemented update_size
    }


    /**
     * Update repaint board with inside zones
     */
    this.update_paint = function() {
	// FIXME: not implemented update_paint
    }


    /**
     * Return zone at given location
     */
    this.get_zone = function( x, y ) {
	// FIXME: not implemented get_zone

    }

    this.initialize();
}
