
// vim: set ts=4 sw=4 et:
"use strict";

if (!("console" in window)) {
    alert("malbu");
    var names = ["log", "debug", "info", "warn", "error", "assert", "dir", "dirxml", "group", "groupEnd", "time", "timeEnd", "count", "trace", "profile", "profileEnd"];
    window.console = {};
    for (var i = 0, len = names.length; i < len; ++i) {
	window.console[names[i]] = function(){};
    }
}

// Object.prototype.to_json = function() { return JSON.stringify( this ); }

