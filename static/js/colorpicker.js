// vim: set ts=4 sw=4 et:
"use strict";

function ColorPicker(p_editor) {
    var self = this,
    _editor,
    _color_picker;

    this.initialize = function ( p_editor ) {
        _editor = p_editor;
        _color_picker = new Color.Picker({
            callback: function(hex) {
                p_editor.color_set( "#" + hex );
            }
        });
        _color_picker.el.style.display = "none";
        $("#session-zone").live("pagehide", function (event) {
            self.hide();
        });
    };

    this.hide = function (p_link) {
        $(_color_picker.el).hide();
    };

    this.is_visible = function () {
        return $(_color_picker.el).is(":visible");
    };

    this.set_color = function ( color ) {
        $("#current_color").css( "background-color",  color );
        _editor.color_set( color );
    };

    this.show = function (p_link) {
        $(_color_picker.el).show();
    };

    this.update_size = function(p_canvas) {
        var offset = $(p_canvas).offset();
        // position
        _color_picker.el.style.position = "absolute";
        _color_picker.el.style.top = offset.top + "px";
        _color_picker.el.style.left = offset.left + "px";
        // resize
        _color_picker.resize($(p_canvas).width() - _color_picker.margin * 2 - _color_picker.hueWidth);
    };

    this.initialize(p_editor);
}
