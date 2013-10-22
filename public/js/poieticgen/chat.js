/******************************************************************************/
/*                                                                            */
/*  Poietic Generator Reloaded is a multiplayer and collaborative art         */
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

/*jslint browser: true, nomen: true */
/*global $, jQuery, document, Zone, console, alert, PoieticGen */

// FIXME: use the prototype-style object definition

(function (PoieticGen, $) {
	"use strict";

	function Chat(p_session) {
		var self = this,

		// FIXME: move HTML template out of javascript file
			_template_received = [
				'<div class="ui-block-a message-src">',
				'<div class="ui-body ui-body-a">from: ',
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
				'<div class="ui-body ui-body-b">to: ',
				"",
				'</div></div>'
			],
			_session;

		this._queue = [];

		this.name = "Chat";

		/**
		* Constructor
		*/
		this.initialize = function (p_session) {
			// register chat to session
			_session = p_session;
			_session.register(self);

			// initialize list of users for the send message form
			this.refresh_user_list();

			// attach submit event
			$("#send-message-form").submit(function (event) {
				event.preventDefault();
				var content = $(this).find("#send-message-form-content"),
					user_dst = $(this).find("#send-message-form-to").val(),
					user_dst_id = parseInt(user_dst, 10),
					message;

				if (null !== user_dst && 0 < user_dst_id && "" !== content.val()) {
					message = {
						content: content.val(),
						stamp: (new Date()).getTime() / 1000,
						user_dst: user_dst_id
					};

					self.queue_message(message);
					self.display_message({
						content: content.val(),
						user_dst: user_dst_id
					}, true);

					// Reset field value.
					content.val("");
				} else {
					alert("You must select an user and write a message.");
				}
			});


			// when the messages page is shown reset unread messages count
			$("#session-chat").live("pageshow", function () {
				$("span.ui-li-count").text(0);
			});
		};

		this.display_message = function (message, is_sent_message) {
			var html;
			if (is_sent_message) {
				html = _template_sent;
				html[2] = message.content;
				html[6] = _session.get_user_name(message.user_dst);
			} else {
				html = _template_received;
				html[2] = _session.get_user_name(message.user_src);
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
		this.handle_event = function (ev) {
			console.log("chat/handle_event : " + JSON.stringify(ev));
			switch (ev.type) {
			case "join": // on both join and leave refresh users list
			case "leave":
				this.refresh_user_list();
				break;
			default: // all other events are ignored
				break;
			}
		};


		/**
		*
		*/
		this.handle_message = function (msg) {
			console.log("chat/handle_message : " + JSON.stringify(msg));
			var liCount = $("span.ui-li-count"), count = parseInt($(liCount).text(), 10), link;
			// refresh unread count and blink for notification only when not on messages page
			if ("session-chat" !== $.mobile.activePage.attr("id")) {
				$(liCount).text(count + 1);
				link = $(liCount).closest("a")
					.removeClass("ui-btn-up-a").addClass("ui-btn-up-e");
				setTimeout(function () {
					$(link).removeClass("ui-btn-up-e").addClass("ui-btn-up-a");
				}, 100);
			}
			if (msg.user_src === _session.user_id) {
				this.display_message(msg, true);
			} else {
				this.display_message(msg, false);
			}
		};


		/**
		* Refresh user list
		*/
		this.refresh_user_list = function () {
			var i,
				select = $("#send-message-form-to");
			console.log("chat/refresh_user_list : " + JSON.stringify(_session.other_users));
			select.empty().selectmenu();
			for (i = 0; i < _session.other_users.length; i += 1) {
				select.append('<option value="'
					+ _session.other_users[i].id + '">'
					+ _session.other_users[i].name
					+ '</option>'
					);
			}
			select.selectmenu("refresh");
		};


		// call initialize method
		this.initialize(p_session);
	}

	PoieticGen.Chat = Chat;

}(PoieticGen, jQuery));

