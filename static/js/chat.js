"use strict";

function Chat (p_session) {
    var _session;

    var self = this;

    this._queue = [];

    this.initialize = function (p_session) {
        // register chat to session
        p_session.register_chat(self);

        // attach submit event
        $("#send-message-form").submit(function(event){
            event.preventDefault();
            var date = new Date(), message = {
                user_dst: parseInt($(this).find("#send-message-form-to").val(), 10),
                stamp: Math.round(date.getTime() / 1000), // timestamp
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
