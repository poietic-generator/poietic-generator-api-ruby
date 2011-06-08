
// vim: set ts=4 sw=4 et:
"use strict";

( function() {
    var names = ["log", "debug", "info", "warn", "error", "assert", "dir", "dirxml", "group", "groupEnd", "time", "timeEnd", "count", "trace", "profile", "profileEnd"];

    window.noconsole = {};

    for (var i = 0, len = names.length; i < len; ++i) {
        window.noconsole[names[i]] = function(){};
    }

    if (!("console" in window)) {
        window.console = window.noconsole;
    }
} )();

