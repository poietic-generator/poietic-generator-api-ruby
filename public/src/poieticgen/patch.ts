
import * as Colors from '../common/colors';

export interface IPosition {
	x: number;
	y: number;
}

export type IChange = [number, number, number];

export interface IPatch {
	changes : IChange[];
	color : Colors.Color | null;
	zone: number | null;
	diff: number | null;
}

export class Patch implements IPatch {
	static readonly LIFESPAN = 500;

	public changes: IChange[];
	public color: Colors.Color | null;
	public zone: number | null;
	public diff: number | null;

	constructor() {
		this.changes = [];
		this.color = null;
		this.zone = null;
		this.diff = null;
	}

	public setColor(newColor: any) { 
		this.color = newColor; 
	};

	public append(pos: IPosition) {
		console.log("patch.append: " + JSON.stringify(pos));
		this.changes = this.changes.concat([pos.x, pos.y, 0]);
	};

	public toJson(): IPatch {
		return {
			'color': this.color,
			'changes': this.changes,
			'diff' : this.diff,
			'zone': this.zone
		};
	};

	public fromJson(patch: IPatch) {
		this.color = patch.color;
		this.changes = patch.changes;
		this.diff = patch.diff;
		this.zone = patch.zone;
	};

	public static fromJson(patch: IPatch) : Patch {
		var res = new Patch();
		res.fromJson(patch);
		return res;
	}

	public static toJson(patch: Patch) : IPatch {
		var res = patch.toJson();
		return res;
	}
}

