
// vim: set ts=4 sw=4 et:
"use strict";

function Zone( p_width, p_height ) {
    var self = this;

    this.width = p_width;
    this.height = p_height;

    var matrix = [];

    console.log("zone/initialize width = %s", this.width );
    console.log("zone/initialize height = %s", this.height );


    /*
     * Set matrix position to given color
     */
    this.pixel_set = function( pos, color ) {
        var idx = Math.floor( pos.y ) * self.width + Math.floor(pos.x);
        console.log("zone/pixel_set idx = %s", idx );
        matrix[idx] = color;
    };


    /* 
     * Get color at given matrix position
     */
    this.pixel_get = function( pos ) {
        var idx = Math.floor( pos.y ) * self.width + Math.floor( pos.x );
        console.log("zone/pixel_get idx = %s", idx );
        return matrix[idx];
    };


    /* 
     * Return whethe given position is inside or outside zone
     */
    this.is_bound = function( pos ) {
        if ( pos.x < 0 ) return false;
        if ( pos.x >= self.width ) return false;
        if ( pos.y < 0 ) return false;
        if ( pos.y >= self.height ) return false;
        return true;
    }

    /*
     * Utility function for debugging
     */
    this.to_s = function() { JSON.stringify(this); };

}

