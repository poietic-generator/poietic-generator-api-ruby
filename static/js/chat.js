"use strict";

function Chat( p_session ) {
    var self = this,
    _template_received = [
        '<div class="ui-block-a message-src">',
        '<div class="ui-body ui-body-a">',
        "",
        '</div></div>',
        '<div class="ui-block-b message-content">',
        '<div class="ui-body ui-body-a">',
        "",
        '</div></div>'
    ],
    _template_sent = [
        '<div class="ui-block-a message-content">',
        '<div class="ui-body ui-body-b message-dst-content">',
        "",
        '</div></div>',
        '<div class="ui-block-b message-dst">',
        '<div class="ui-body ui-body-b">',
        "",
        '</div></div>'
    ];

    this._queue = [];

    /**
     * Constructor
     */
    this.initialize = function (p_session) {
        // register chat to session
        p_session.register(self);

        // initialize list of users for the send message form
        if (0 < p_session.other_users.length) {
            var select = $("#send-message-form-to");
            for (var i=0; i < p_session.other_users.length; i++) {
                select.append('<option value="'
                              + p_session.other_users[i].id + '">'
                              + p_session.other_users[i].name
                              + ' (' + p_session.other_users[i].id + ')</option>');
            }
        }

        // attach submit event
        $("#send-message-form").submit(function(event){
            var content = $(this).find("#send-message-form-content");
            event.preventDefault();
            var message = {
                content: content.val(),
                stamp: new Date(),
                user_dst: parseInt($(this).find("#send-message-form-to").val(), 10)
            };
            self.queue_message( message );
            self.display_message({
                content: content.val(),
                user_dst: "me"
            }, true);
            // Reset field value.
            content.val("");
        });
    };

    this.display_message = function (message, is_sent_message) {
        var html;
        if (is_sent_message) {
            html = _template_sent;
            html[2] = message.content;
            html[6] = message.user_dst;
        } else {
            html = _template_received;
            html[2] = message.user_dst;
            html[6] = message.content;
        }
        $("#message-contener").prepend(html.join(""));
    };


    this.queue_message = function (message) {
        this._queue.push(message);
    };


    /**
     *
     */
    this.get_messages = function () {
        var queue   = self._queue;
        self._queue = [];
        return queue;
    };


    /**
     *
     */
    this.handle_message = function( msg ) {
        console.log("chat/handle_message : %s", JSON.stringify( msg ));
        this.display_message(msg, false);
    }


    // call initialize method
    this.initialize( p_session );
}

