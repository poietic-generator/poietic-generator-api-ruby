/******************************************************************************/
/*                                                                            */
/*  Poetic Generator Reloaded is a multiplayer and collaborative art          */
/*  experience.                                                               */
/*                                                                            */
/*  Copyright (C) 2011 - Gnuside                                              */
/*                                                                            */
/*  This program is free software: you can redistribute it and/or modify it   */
/*  under the terms of the GNU Affero General Public License as published by  */
/*  the Free Software Foundation, either version 3 of the License, or (at     */
/*  your option) any later version.                                           */
/*                                                                            */
/*  This program is distributed in the hope that it will be useful, but       */
/*  WITHOUT ANY WARRANTY; without even the implied warranty of                */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero  */
/*  General Public License for more details.                                  */
/*                                                                            */
/*  You should have received a copy of the GNU Affero General Public License  */
/*  along with this program.  If not, see <http://www.gnu.org/licenses/>.     */
/*                                                                            */
/******************************************************************************/

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
            $("#brush").removeClass( "ui-btn-active" );
        });
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
        var position = $(p_canvas).position();
        // position
        _color_picker.el.style.position = "absolute";
        _color_picker.el.style.top = position.top + "px";
        _color_picker.el.style.left = position.left + "px";
        // resize
        _color_picker.resize($(p_canvas).width() - _color_picker.margin * 2 - _color_picker.hueWidth);
    };

    this.initialize(p_editor);
}
