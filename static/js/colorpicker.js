// vim: set ts=4 sw=4 et:
"use strict";

function ColorPicker(p_editor) {
    var self = this;
    var _color_picker;

    this.initialize = function (p_editor) {
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
        $(p_link)
            .attr("data-icon", "plus")
            .find("span.ui-icon-minus")
            .removeClass("ui-icon-minus")
            .addClass("ui-icon-plus");
    };

    this.is_visible = function () {
        return $(_color_picker.el).is(":visible");
    };

    this.show = function (p_link) {
        $(_color_picker.el).show();
        $(p_link)
            .attr("data-icon", "minus")
            .find("span.ui-icon-plus")
            .removeClass("ui-icon-plus")
            .addClass("ui-icon-minus");
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
