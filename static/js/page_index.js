"use strict";

function setUsernameCookie () {
    $.cookie(
        "user_name",
        $("#credentials").find("input#username").val(),
        {path: "/"}
    );
}

$(document).ready(function() {
    var user_name = $.cookie('user_name');
    if (user_name) {
        $("#username").val(user_name);
    }
    $("#credentials").submit(function (event) {
        event.preventDefault();
        setUsernameCookie();
        document.location = $(this).attr("action");
    });
    $("#link_play").click(function (event) {
        setUsernameCookie();
        return true;
    });
});
