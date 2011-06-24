/******************************************************************************/
/*                                                                            */
/*  Poetic Generator Reloaded is a multiplayer and collaborative art          */
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


/**
 * Global view
 */
function Board( p_session ) {
	var console = window.noconsole;

	var self = this;

    this.name = "Board";

	var _real_canvas = null;
	var _context = null;
	var _zones = null;
	var _users = null;
	var _session = null;


	/**
	 * Constructor
	 */
	this.initialize = function( p_session ) {

		_session = p_session;
		_session.register( self );
		_zones = {};
		_users = {};

		// fill zones with zones from session
		_zones[_session.user_zone.index] = new Zone(
				_session,
				_session.user_zone.index,
				_session.user_zone.position,
				_session.zone_column_count,
				_session.zone_line_count
				);

		for (var i=0; i<p_session.other_zones.length; i++) {
			var z = p_session.other_zones[i];

			_zones[z.index] = new Zone(
					_session,
					z.index, z.position,
					_session.zone_column_count, _session.zone_line_count
					);
		}
		console.log("board/initialize: zones = %s", JSON.stringify( _zones ) );
	}


	/**
	 *
	 */
	this.handle_event = function( ev ) {
		console.log("board/handle_event : %s", JSON.stringify( ev ) );
		if ( ev.type == 'join' ) {
			var z = ev.desc.zone;
			_zones[z.index] = new Zone(
					_session,
					z.index, z.position,
					_session.zone_column_count, _session.zone_line_count
					);
		} else if ( ev.type == 'leave' ) {
			var z = ev.desc.zone;
			console.log("board/handle_event: _zones bf splice %s", JSON.stringify( _zones ) );
			_zones.splice(z.index,1);
		} else {
			// FIXME: unknown event...
		}
	}


	/**
	 *
	 */
	this.get_zone = function( index ) {
		// console.log("board/get_zone(%s) : %s", index, JSON.stringify( _zones[index] ) );
		return _zones[index];
	}


	/**
	 * Return the list of existing zone ids
	 */
	this.get_zone_list = function() {
		var keys = [];
		for(var i in _zones) {
			if (_zones.hasOwnProperty(i))
			{
				keys.push( parseInt(i,10) );
			}
		}
		// console.log("board/get_zone_list : %s", JSON.stringify( keys ));
		return keys;
	}


	/**
	 *
	 */
	this.handle_stroke = function( stk ) {
		console.log("board/handle_stroke : stroke = %s", JSON.stringify( stk ));
		console.log("board/handle_stroke : zones = %s", JSON.stringify( _zones ));
		var z = _zones[stk.zone];
		if (z) {
			z.patch_apply( stk );
		} else {
			console.warn("board/handle_stroke: trying to apply stroke for missing zone %s", stk.zone);
		}
	}


	this.initialize( p_session );
}

