"use strict";

$(document).ready(function() {
    $("#link_play").click(function (event) {
        $.cookie("user_name", $("#credentials").find("input#username").val());
        return true;
    });
});
