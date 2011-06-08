// vim: set ts=4 sw=4 et:
"use strict";

function ColorPicker(p_editor) {
    var _color_picker;

    this.initialize = function (p_editor) {
        _color_picker = new Color.Picker({
            callback: function(hex) {
                p_editor.color_set( "#" + hex );
            }
        });
        _color_picker.el.style.display = "none";
    };

    this.hide = function () {
        $(_color_picker.el).hide();
    };

    this.is_visible = function () {
        return $(_color_picker.el).is(":visible");
    };

    this.show = function () {
        $(_color_picker.el).show();
    };

    this.update_size = function(p_canvas) {
        // position
        _color_picker.el.style.position = p_canvas.style.position;
        _color_picker.el.style.top = p_canvas.style.top;
        _color_picker.el.style.left = p_canvas.style.left;
        // resize
        _color_picker.resize($(p_canvas).width());
    };

    this.initialize(p_editor);
}
