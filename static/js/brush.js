
function SmallBrush() {
	this.size = 1;
	this.center = { x:0, y:0 };
	this.def = [ 1 ];
}

function NormalBrush() {
	this.size = 2;
	this.center = { x:0, y:0 };
	this.def = [ 1, 1, 1, 1 ];
}

function LargeBrush() {
	this.size = 3;
	this.center = { x: 0, y:0 }
	this.def = [ 
		0, 1, 0, 
		1, 1, 1,
		0, 1, 0 ];
}

