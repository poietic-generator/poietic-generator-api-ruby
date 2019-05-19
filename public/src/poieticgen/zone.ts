
import { Patch, IPatch, IPosition, IChange } from '../poieticgen/patch';
import * as Colors from '../common/colors';

export class Zone {
	public static BACKGROUND_COLOR = '#000';

	private _session : any;

	//color matrix (for maintaining state localy)
	private _matrix : any[] = [];
	// patches to send
	private _output_queue: Patch[] = [];
	// the patch we are working on
	private _current_patch: Patch | null = null;
	// patches to apply localy
	private _input_queue: Patch[] = [];

	public index: number;
	public position: IPosition;
	public width: number;
	public height: number;
	public session: any;

	constructor(p_session: any, 
				p_index: number, 
				p_position: IPosition, 
				p_width: number, 
				p_height: number) {
		// zone dimensions
		this.index = p_index;
		this.position = p_position;
		this.width = p_width;
		this.height = p_height;
		this.session = p_session;

		this.matrixInitialize();
	}


	private _create_patch(pos: IPosition, color: Colors.Color): Patch {
		var date: any= new Date();
		var diff: number= (date - this._session.last_update_time);
		var patch = new Patch();
		patch.fromJson({
			zone: this.index,
			diff: Math.floor(diff / 1000),
			color: color,
			changes: [ [ pos.x, pos.y, 0 ] ]
		});
		return patch;
	};


	// console.log("zone/initialize width = " + this.width );
	// console.log("zone/initialize height = " + this.height );

	/**
	 * Set matrix default color
	 */
	private matrixInitialize() {
		var imax = this.width * this.height,
			i;
		for (i = 0; i < imax; i += 1) {
			this._matrix[i] = Zone.BACKGROUND_COLOR;
		}
	};


	/*
	 * Set matrix position to given color
	 */
	public pixelSet(pos: IPosition, color: Colors.Color) {
		var idx = Math.floor(pos.y) * this.width + Math.floor(pos.x);
		// console.log("zone/pixel_set idx = " + idx );
		this._matrix[idx] = color;
	};


	/*
	 * Get color at given matrix position
	 */
	public pixelGet(pos: IPosition) {
		var idx = Math.floor(pos.y) * this.width + Math.floor(pos.x);
		// console.log("zone/pixel_get idx = " + idx );
		return this._matrix[idx];
	};


	/*
	 * Return whethe given position is inside or outside zone
	 */
	public containsPosition(pos: IPosition) {
		if (pos.x < 0) { return false; }
		if (pos.x >= this.width) { return false; }
		if (pos.y < 0) { return false; }
		if (pos.y >= this.height) { return false; }
		return true;
	};


	/**
	 * Create patch out of latest changes
	 */
	public patchRecord(pos: IPosition, color: Colors.Color) {
		var patch_update,
			patch_enqueue,
			prev_record = null;

		if (this._current_patch === null) {
			// console.log("zone/patch_record: patch creation!");
			this._current_patch = this._create_patch(pos, color);
		} else {
			if (this._current_patch.color !== color) {
				this.patchEnqueue();
				this._current_patch = this._create_patch(pos, color);
			} else {
				// console.log("zone/patch_record: patch update!");

				// CONSTRAINT : we drop duplicate coordinates from a single patch if latest record it the same
				if (this._current_patch.changes.length > 0) {
					prev_record = this._current_patch.changes[this._current_patch.changes.length - 1];
				}

				if ((prev_record === null) || (prev_record[0] !== pos.x)
					|| (prev_record[1] !== pos.y)) {
					this._current_patch.changes.push([ pos.x, pos.y, 0 ]);
				}
			}
		}
		// console.log( "zone/patch_record: _current_patch = " + JSON.stringify( _current_patch ) );
	};


	/**
	 * Push current patch to local patch queue
	 */
	public patchEnqueue() {
		//console.log("zone/patch_enqueue: !");
		if (this._current_patch !== null) {
			this._output_queue.push(this._current_patch);
			this._session.dispatch_strokes([ this._current_patch ]);
			this._current_patch = null;
			console.log("zone/patch_enqueue: output queue = " + JSON.stringify(this._output_queue));
		}
	};


	/**
	 *
	 */
	public patchesGet() {
		var aggregate = [];

		while (this._output_queue.length > 0) {
			// FIXME: compute relative time since last sync
			aggregate.push(this._output_queue.shift());
		}

		return aggregate;
	};


	/**
	 * Request application for a set of patches to current zone
	 */
	public patchApply(p_patch: Patch) {
		var color = p_patch.color,
			cgset = null,
			zone_pos = null,
			i;

		if (color === null) return;

		for (i = 0; i < p_patch.changes.length; i += 1) {
			cgset = p_patch.changes[i];
			zone_pos = { x: cgset[0], y: cgset[1] };
			this.pixelSet(zone_pos, color);
		}
	};


	/**
	 *
	 */
	public patchesPush(p_patches: Patch[]) {
		// FIXME: call apply patch for each patches' relative time
		// FIXME : append aggregate  instead of replacing
		this._input_queue = p_patches;
	};

	// constructor
};

