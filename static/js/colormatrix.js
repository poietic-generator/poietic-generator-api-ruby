
// vim: set ts=4 sw=4 et:

function ColorMatrix( p_width, p_height ) {
    var matrix = [];
    var width = p_width;
    var height = p_height;

    this.width = function() { return width; };

    this.height = function() { return height; };

    this.pixel_set = function( pos, color ) {
        var idx = pos.y * width + pos.x;
        matrix[idx] = color;
    };

    this.pixel_get = function( pos ) {
        var idx = pos.y * width + pos.x;
        return matrix[idx];
    }

}
