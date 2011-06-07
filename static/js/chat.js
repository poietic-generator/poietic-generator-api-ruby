"use strict";

function Chat (p_session) {
    var _session;

    var self = this;

    this._queue = [];

    this.initialize = function (p_session) {
        // register chat to session
        p_session.register_chat(self);

        // initialize list of users for the send message form
        if (0 < p_session.other_users.length) {
            var select = $("#send-message-form-to");
            for (var i=0; i < p_session.other_users.length; i++) {
                select.append('<option value="' + p_session.other_users[i].id + '">' + p_session.other_users[i].name + ' (' + p_session.other_users[i].id + ')</option>');
            }
        }

        // attach submit event
        $("#send-message-form").submit(function(event){
            event.preventDefault();
	    var message = {
                user_dst: parseInt($(this).find("#send-message-form-to").val(), 10),
                stamp: new Date(),
                content: $(this).find("#send-message-form-content").val()
            };
            self.queueMessage(message);

            // close send message dialog
            $(".ui-dialog").dialog("close");
        });
    };

    this.getQueue = function () {
        var queue   = this._queue;
        this._queue = [];
        return queue;
    };

    this.queueMessage = function (message) {
        this._queue.push(message);
    };

    // call initialize method
    this.initialize(p_session);
}
