
const PATCH_LIFESPAN = 3000;

/*
function PatchQueue() {
}
*/

function Patch() {
	var self = this;
	var color = null;
	var changes = [];

	this.set_color = function( new_color ) {
		color = new_color;
	};

	this.append = function( pos ) {
		console.log( "patch.append: %s", JSON.stringify( pos ) );
		changes = changes.concat( [ pos.x, pos.y ] );
	};

	this.to_json = function() {
		return { 
			'color': color,
			'changes': changes,
		};	
	};

	this.from_json = function( patch ) {
		color = patch.color;
		changes = patch.changes;
	};

}

