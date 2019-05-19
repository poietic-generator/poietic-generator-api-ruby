
var session = null,
	viewer = null,
	board = null,
	editor = null,
	chat = null,
	bot = null,
	username = null,
	KEY_LEFT = 37,
	KEY_UP = 38,
	KEY_RIGHT = 39,
	KEY_DOWN = 40,
	KEY_A = 65,
	KEY_B = 66,
	bot_cur_key = 0, 
	bot_keys;

bot_keys = [ KEY_UP, KEY_UP,
	KEY_DOWN, KEY_DOWN,
	KEY_LEFT, KEY_RIGHT,
	KEY_LEFT, KEY_RIGHT,
	KEY_B,
	KEY_A ];

if (PoieticGen.Zone === undefined) {
	console.error("PoieticGen.Zone is not defined !");
}
if (PoieticGen.Editor === undefined) {
	console.error("PoieticGen.Editor is not defined !");
}
if (PoieticGen.Chat === undefined) {
	console.error("PoieticGen.Chat is not defined !");
}
if (PoieticGen.Viewer === undefined) {
	console.error("PoieticGen.Viewer is not defined !");
}

function bot_keydown_handle(event) {
	if (bot_cur_key < bot_keys.length && event.keyCode === bot_keys[bot_cur_key]) {
		bot_cur_key += 1;

		if (bot_cur_key >= bot_keys.length) {
			if (null === bot) {
				bot = new PoieticGen.Bot(editor);
			}
			if (bot.started()) {
				bot.stop();
			} else {
				bot.draw_lines();
			}

			bot_cur_key = 0;
		}
	} else if (bot_cur_key !== 0) {
		bot_cur_key = 0;
		bot_keydown_handle(event);
	} else {
		bot_cur_key = 0;
	}
}

// instead of windows.onload
$(document).ready(function () {


	$(".logout").bind("click", function (event) {
		event.preventDefault();
		if (!confirm("Leave Poietic Generator?")) {
			return false;
		}
		document.location = $(this).attr("href") + "/" + session.user_token;
		return false;
	});

	// initialize zones
	session = new PoieticGen.DrawSession(
		function (session) {
			//console.log("page_draw/ready: session callback ok");


			board = new PoieticGen.Board(session);
			editor = new PoieticGen.Editor(session, board, 'session-editor');
			//var color_picker = new ColorPicker( editor );
			chat = new PoieticGen.Chat(session);
			viewer = new PoieticGen.Viewer(session, board, 'session-viewer', editor);
			username = new PoieticGen.Username({
				session: session,
				onupdate: function update_ui(name) {
					// update various location with name
					$(".username").text(name);
					$("#usernameDialog #un").val(name);
				}
			});

			$("#usernameDialog form").bind("submit", function (event) {
				// change username & close popup
				username.change($('#un').val());
				$('#usernameDialog').popup('close');
				return false;
			});

			//console.log("page_draw/ready: prepicker");
			$("#brush").bind("vclick", function (event) {
				var result;
				event.preventDefault();
				if (true === editor.is_color_picker_visible()) {
					result = editor.hide_color_picker(this);
				} else {
					result = editor.show_color_picker(this);
				}
				return result;
			});

			$("#canvas-container").bind("vclick", function (event) {
				if (true === editor.is_color_picker_visible()) {
					editor.hide_color_picker($("#brush"));
				}
			});
		}
	);

	// Bot starts with the KONAMI sequence of keys
	$(document).bind("keydown", bot_keydown_handle);
});

