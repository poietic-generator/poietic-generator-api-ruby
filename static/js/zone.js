
// vim: set ts=4 sw=4 et:
"use strict";

const ZONE_BACKGROUND_COLOR = '#000';

function Zone( p_width, p_height ) {
    var self = this;

    // zone dimensions
    this.width = p_width;
    this.height = p_height;

    // color matrix (for maintaining state localy)
    var _matrix = [];

    // patches to send
    var _local_patches = [];

    // the patch we are working on
    var _current_patch = null;

    // patches to apply localy
    var _remote_patches = [];

    // console.log("zone/initialize width = %s", this.width );
    // console.log("zone/initialize height = %s", this.height );

    /**
     * Set matrix default color
     */
    this.matrix_initialize = function() {
        var imax = self.width * self.height;
        for (var i=0; i<imax; i++){
            _matrix[i] = ZONE_BACKGROUND_COLOR;
        }
    }


    /*
     * Set matrix position to given color
     */
    this.pixel_set = function( pos, color ) {
        var idx = Math.floor( pos.y ) * self.width + Math.floor(pos.x);
        // console.log("zone/pixel_set idx = %s", idx );
        _matrix[idx] = color;
    };


    /* 
     * Get color at given matrix position
     */
    this.pixel_get = function( pos ) {
        var idx = Math.floor( pos.y ) * self.width + Math.floor( pos.x );
        // console.log("zone/pixel_get idx = %s", idx );
        return _matrix[idx];
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


    /**
     * Create patch out of latest changes
     */
    this.patch_record = function( pos, color ) {
        var patch_update;
        var patch_enqueue;

        if ( _current_patch == null ) {
            // console.log("zone/patch_record: patch creation!");
            _current_patch = {
                stamp: new Date(),
                color: color,
                changes: [ { x: pos.x, y: pos.y, stamp: 0 }  ]
            }
        } else {
            if ( _current_patch.color == color) {
                self.patch_enqueue();
                _current_patch = {
                    stamp: new Date(),
                    color: color,
                    changes: [ { x: pos.x, y: pos.y, stamp: 0 }  ]
                }
            } else {
                // console.log("zone/patch_record: patch update!");

                _current_patch.changes.push( { x: pos.x, y: pos.y, stamp: 0 });
            }
        }
    };


    /**
     * Push current patch to local patch queue
     */
    this.patch_enqueue = function() {
        _local_patches.push(_current_patch);
        _current_patch = null;
    };


    /*
     * Utility function for debugging
     */
    this.to_s = function() { JSON.stringify(this); };


    // constructor
    self.matrix_initialize();

}

