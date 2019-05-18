
declare class Editor { 
	column_count: number;
	line_count: number;
	pixel_set : (arg0: any, arg1: any) => any;
};

// import { Editor } from '../poieticgen/editor';
import * as Colors from '../common/colors';

enum Direction {
	North,
	South,
	East,
	West,
	NorthWest,
	SouthWest,
	NorthEast,
	SouthEast
}

interface Point2D {
	x: number;
	y: number;
}


class Bot {
	readonly INTERVAL_AGRESSIVE = 40;
	readonly INTERVAL_STANDARD = 500;
	readonly INTERVAL_KIND = 1500;
	readonly STROKE_INTERVAL = this.INTERVAL_KIND;

	private _editor : Editor;
	private _base_hue = 0;
	private _started = false;
	private _current_line = 0;
	private _timer : any;
	
	constructor (p_editor : Editor) {
		this._editor = p_editor;
		this._base_hue = Math.floor(Math.random() * 360);
		this._current_line = 0;
	}

	private drawRandomLine = (local_pos:Point2D, length:number, direction : Direction) => {
		var color_hex, px_id, random_direction;

		if (typeof local_pos === 'undefined') {
			local_pos = {
				x: Math.floor(Math.random() * this._editor.column_count),
				y: Math.floor(Math.random() * this._editor.line_count)
			};
		}

		color_hex = Colors.randomHex();
		if (typeof length === 'undefined') {
			length = Math.floor(Math.random() * this._editor.column_count);
		}
		random_direction = typeof direction === 'undefined';

		for (px_id = 0; px_id < length; px_id += 1) {

			if (local_pos.x < this._editor.column_count
				&& local_pos.y < this._editor.line_count) {
				this._editor.pixel_set(local_pos, color_hex);
			}

			if (random_direction === true) {
				direction = Math.floor(Math.random() * 5);
			}
			switch (direction) {
				case Direction.West:
					local_pos.x += 1;
					break;
				case Direction.East:
					local_pos.x += 1;
					break;
				case Direction.South:
					local_pos.y += 1;
					break;
				case Direction.North:
					local_pos.y -= 1;
					break;
				case Direction.SouthWest:
					local_pos.y += 1;
					local_pos.x += 1;
					break;
				case Direction.NorthWest:
					local_pos.y -= 1;
					local_pos.x += 1;
					break;
			}
		}
	};


	public drawDots = () => {
		var local_pos : Point2D = {
			x: Math.floor(Math.random() * this._editor.column_count),
			y: Math.floor(Math.random() * this._editor.line_count)
		};

		this.stop();
		this._started = true;
		this._editor.pixel_set(local_pos, Colors.randomHex());
		this._timer = window.setTimeout(this.drawDots, this.STROKE_INTERVAL);
	};


	public drawLines = () => {
		var length = this._editor.column_count, local_pos = {
			x: 0,
			y: this._current_line
		};

		this.stop();
		this._started = true;
		this._current_line = (this._current_line + 1) % this._editor.line_count;

		this.drawRandomLine(local_pos, length, 0);

		if (this._current_line === 0) {
			this._base_hue = Math.floor(Math.random() * 360);
		}

		this._timer = window.setTimeout(this.drawLines, this.STROKE_INTERVAL);
	};


	public stop = () => {
		if (typeof(this._timer) !== 'undefined') {
			window.clearTimeout(this._timer);
			this._timer = undefined;
		}
		this._started = false;
	};


	public started = () => (this.started);
}

export default Bot;

