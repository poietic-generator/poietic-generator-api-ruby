import * as $ from "jquery"; 

// instead of windows.onload
$(document).ready(function () {
    var admin_token_parameter = /admin_token=(\w+)/.exec(location.search);

    if (admin_token_parameter !== null && admin_token_parameter.length === 2) {
	    $.cookie('admin_token', admin_token_parameter[1], {path: "/"});
    }
});

