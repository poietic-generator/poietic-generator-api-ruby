
import { Zone } from '../poieticgen/zone';
import { Patch } from '../poieticgen/patch';

/**
 * Global view
 */
export class Board {
	private realCanvas : any;
	private context : any;
	private zones : { [s: string]: Zone; } = {};
	private users : { [s: string]: Zone; } = {}
	private session : any;

	/**
	 * Constructor
	 */
    constructor (p_session: any) {
		// loop vars
		var i, z;

		session = p_session;
		session.register(self);

		// fill zones with zones from session
		if (undefined !== session.user_zone) {
			this.zones[session.user_zone.index] = new Zone(
				session,
				session.user_zone.index,
				session.user_zone.position,
				session.zone_column_count,
				session.zone_line_count
			);
		}

		for (i = 0; undefined !== p_session.other_zones && i < p_session.other_zones.length; i += 1) {
			z = p_session.other_zones[i];

			this.zones[z.index] = new Zone(
				session,
				z.index,
				z.position,
				session.zone_column_count,
				session.zone_line_count
			);
		}
		console.log("board/initialize: zones = " + JSON.stringify(this.zones));
    }



	/**
	 *
	 */
	public handleEvent(ev: any) {
		var z;
		console.log("board/handle_event : " + JSON.stringify(ev));
		if (ev.type === 'join') {
			z = ev.desc.zone;
			this.zones[z.index] = new Zone(
				this.session,
				z.index,
				z.position,
				this.session.zone_column_count,
				this.session.zone_line_count
			);
		} else if (ev.type === 'leave') {
			z = ev.desc.zone;
			console.log("board/handle_event: _zones bf delete " + JSON.stringify(this.zones));
			delete this.zones[z.index];
		} else {
			console.log("board/handle_event: unknown event");
		}
	};


	/**
	 *
	 */
	public getZone(index: number) {
		// console.log("board/get_zone("+ index + ") : " + JSON.stringify( _zones[index] ) );
		return this.zones[index];
	};


	/**
	 * Return the list of existing zone ids
	 */
	public getZoneList() {
		var keys = [],
			i;

		for (i in this.zones) {
			if (this.zones.hasOwnProperty(i)) {
				keys.push(parseInt(i, 10));
			}
		}
		// console.log("board/get_zone_list : " + JSON.stringify( keys ));
		return keys;
	};


	/**
	 *
	 */
	public handleStroke(stk: Patch) {
		var z = (stk.zone !== null) ? this.zones[stk.zone] : null;

		console.log("board/handle_stroke : stroke = " + JSON.stringify(stk));
		console.log("board/handle_stroke : zones = " + JSON.stringify(this.zones));
		if (z) {
			z.patchApply(stk);
		} else {
			console.warn("board/handle_stroke: trying to apply stroke for missing zone " + stk.zone);
		}
	};


	public handleReset(session) {
		console.log("board/handle_reset");
		this.initialize(session);
	};

}

