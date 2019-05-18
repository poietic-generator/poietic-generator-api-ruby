
import * as Colors from '../common/colors';

export class Picker {
	public callback: any;
	public hue: number;
	public sat: number;
	public val: number;
	public element: any;
	public el: any;
	public size: number;
	public margin: number;
	public offset: number;
	public hueWidth: number;
	public colorCanvas: any;
	public colorCtx: any;
	public plugin: any;
	public circle: any;

	constructor(props?: any) {
    	/// loading properties
    	if (typeof(props) == "undefined") props = {};
    	this.callback = props.callback; // bind custom function
    	this.hue = props.hue || 0; // 0-360
    	this.sat = props.sat || 0; // 0-100
    	this.val = props.val || 100; // 0-100
    	this.element = props.element || document.body;
    	this.size = props.size || 165; // size of colorpicker
    	this.margin = 10; // margins on colorpicker
    	this.offset = this.margin / 2;
    	this.hueWidth = 30;

    	/// creating colorpicker (header)
    	this.plugin = this.createComponentColorPicker();

		var hexClose = this.createComponentHexClose();
    	var arrows = this.createComponentArrows();

		this.circle = this.createCircleSelection();

    	/// creating colorpicker sliders
    	this.colorCanvas = document.createElement("canvas");
    	this.colorCtx = this.colorCanvas.getContext("2d");
    	this.colorCanvas.style.cssText = "position: absolute; top: 19px; left: " + (this.offset) + "px;";
    	this.colorCanvas.width = this.size + this.hueWidth + this.margin;
    	this.colorCanvas.height = this.size + this.margin;
    	this.plugin.appendChild(this.colorCanvas);

    	this.plugin.onmousemove = this.mouseManager;
    	this.plugin.onmousedown = this.mouseManager;

    	// appending to element
    	this.element.appendChild(this.plugin);

    	/// helper functions
    	this.el = this.plugin;

    	// drawing color selection
    	this.drawSample();

    	return this;
	};

	private createComponentHexClose = () => {
    	var hexClose = document.createElement("div");
    	hexClose.className = "hexClose";
    	hexClose.textContent = "X";
    	hexClose.onclick = () => { // close colorpicker
			this.plugin.style.display = 
				(this.plugin.style.display == "none") ? "block" : "none";
    	};
    	this.plugin.appendChild(hexClose);
    	this.plugin.appendChild(document.createElement("br"));
	};

	private createComponentArrows = () => {
    	var arrows;
		var ctx : any;
		var width = 3;
		var height = 5;
		var size = 9;
		var top = -size / 4;
		var left = 1;
    	
    	arrows = document.createElement("canvas");
    	arrows.width = 40;
    	arrows.height = 5;

		ctx = arrows.getContext("2d");
		width = 3;
		height = 5;
		size = 9;
		top = -size / 4;
		left = 1;
		for (var n = 0; n < 20; n++) { // multiply anti-aliasing
	    	ctx.beginPath();
	    	ctx.fillStyle = "#FFF";
	    	ctx.moveTo(left + size / 4, size / 2 + top);
	    	ctx.lineTo(left, size / 4 + top);
	    	ctx.lineTo(left, size / 4 * 3 + top);
	    	ctx.fill();
		}
		ctx.translate(width, height);
		ctx.rotate(180 * Math.PI / 180); // rotate arrows
		ctx.drawImage(arrows, -29, 0);
		ctx.translate(-width, -height);

		return arrows;
	}

	private createComponentColorPicker = () => {
    	var plugin;
    	var hexBox;
    	var hexString;

    	plugin = document.createElement("div");
    	plugin.id = "colorjack_square";
    	plugin.style.cssText = "height: " + (this.size + this.margin * 2) + "px";
    	plugin.style.cssText+= ";width:" + (this.size + this.margin + this.hueWidth) + "px";

    	hexBox = this.createComponentHexBox();
    	hexString = this.createComponentHexString();

    	this.plugin.appendChild(hexBox);
    	this.plugin.appendChild(hexString);
    	return plugin;
	};

	private createComponentHexBox = () => {
    	// shows current selected color as the background of this box
    	var hexBox = document.createElement("div");
    	hexBox.className = "hexBox";
    	return hexBox;
	}

	private createComponentHexString = () => {
    	// shows current selected color as HEX string
    	var hexString = document.createElement("div");
    	hexString.className = "hexString";
    	return hexString;
	}

	private createCircleSelection = () => {
		var circle: HTMLCanvasElement;
		var ctx: any;
		var x;
		var y;

		circle = document.createElement("canvas");
    	circle.width = 10;
    	circle.height = 10;
		ctx = circle.getContext("2d");
		ctx.lineWidth = 1;
		ctx.beginPath();
		x = circle.width / 2;
		y = circle.width / 2;
		ctx.arc(x, y, 4.5, 0, Math.PI * 2, true);
		ctx.strokeStyle = '#000';
		ctx.stroke();
		ctx.beginPath();
		ctx.arc(x, y, 3.5, 0, Math.PI * 2, true);
		ctx.strokeStyle = '#FFF';
		ctx.stroke();
		return circle;
	}

	private mouseManager = (e:any) => {
		var down = (e.type == "mousedown");
		var offset = this.margin / 2;
		var abs = abPos(this.colorCanvas);
		var x0 = (e.pageX - abs.x) - offset;
		var y0 = (e.pageY - abs.y) - offset;
		var x = clamp(x0, 0, this.colorCanvas.width);
		var y = clamp(y0, 0, this.size);
		if (e.target.className == "hexString") {
	    	this.plugin.style.cursor = "text";
	    	return; // allow selection of HEX
		} else if (x <= this.size) { // saturation-value selection
	    	this.plugin.style.cursor = "crosshair";
	    	if (down) dragElement({
				type: "relative",
				event: e,
				element: this.colorCanvas,
				callback: function (coords: {x: any, y: any}, state: any) {
		    		var x = clamp(coords.x - this.offset, 0, this.size);
		    		var y = clamp(coords.y - this.offset, 0, this.size);
		    		this.sat = x / this.size * 100; // scale saturation
		    		this.val = 100 - (y / this.size * 100); // scale value
		    		this.drawSample();
				}
	    	});
		} else if (x > this.size + this.margin && x <= this.size + this.hueWidth) { // hue selection
	    	this.plugin.style.cursor = "crosshair";
	    	if (down) dragElement({
				type: "relative",
				event: e,
				element: this.colorCanvas,
				callback: function (coords: any, state: any) {
		    		var y = clamp(coords.y - this.offset, 0, this.size);
		    		this.hue = Math.min(1, y / this.size) * 360;
		    		this.drawSample();
				}
	    	});
		} else { // margin between hue/saturation-value
	    	this.plugin.style.cursor = "default";
		}
		return false; // prevent selection
    };

    public resize = (new_size: number) => {
        this.size = new_size;
        // resize elements
        this.plugin.style.height = (this.size + this.margin * 2) + "px";
        this.plugin.style.width = (this.size + this.margin + this.hueWidth) + "px";
        this.colorCanvas.width = this.size + this.hueWidth + this.margin;
        this.colorCanvas.height = this.size + this.margin;
        // redraw
        this.drawSample();
    };

    public destroy = () => {
		document.body.removeChild(this.plugin);
		for (var key in this) delete this[key];
    };

    public drawHue = () => {
		// drawing hue selector
		var left = this.size + this.margin + this.offset;
		var gradient = this.colorCtx.createLinearGradient(0, 0, 0, this.size);
		gradient.addColorStop(0, "rgba(255, 0, 0, 1)");
		gradient.addColorStop(0.15, "rgba(255, 255, 0, 1)");
		gradient.addColorStop(0.3, "rgba(0, 255, 0, 1)");
		gradient.addColorStop(0.5, "rgba(0, 255, 255, 1)");
		gradient.addColorStop(0.65, "rgba(0, 0, 255, 1)");
		gradient.addColorStop(0.8, "rgba(255, 0, 255, 1)");
		gradient.addColorStop(1, "rgba(255, 0, 0, 1)");
		this.colorCtx.fillStyle = gradient;
		this.colorCtx.fillRect(left, this.offset, 20, this.size);
		// drawing outer bounds
		this.colorCtx.strokeStyle = "rgba(255,255,255,0.2)";
		this.colorCtx.strokeRect(left + 0.5, this.offset + 0.5, 19, this.size-1);
    };

    public drawSquare = () => {
		// retrieving hex-code
		var hex = Colors.hsvToHex({
	    	h: this.hue,
	    	s: 100,
	    	v: 100
		});
		var offset = this.offset;
		var size = this.size;
		// drawing color
		this.colorCtx.fillStyle = "#" + hex;
		this.colorCtx.fillRect(offset, offset, size, size);
		// overlaying saturation
		var gradient = this.colorCtx.createLinearGradient(offset, offset, size + offset, 0);
		gradient.addColorStop(0, "rgba(255, 255, 255, 1)");
		gradient.addColorStop(1, "rgba(255, 255, 255, 0)");
		this.colorCtx.fillStyle = gradient;
		this.colorCtx.fillRect(offset, offset, size, size);
		// overlaying value
		var gradient = this.colorCtx.createLinearGradient(offset, offset, 0, size + offset);
		gradient.addColorStop(0, "rgba(0, 0, 0, 0)");
		gradient.addColorStop(1, "rgba(0, 0, 0, 1)");
		this.colorCtx.fillStyle = gradient;
		this.colorCtx.fillRect(offset, offset, size, size);
		// drawing outer bounds
		this.colorCtx.strokeStyle = "rgba(255,255,255,0.15)";
		this.colorCtx.strokeRect(offset+0.5, offset+0.5, size-1, size-1);
    };

    public drawSample = () => {
		// clearing canvas
		this.colorCtx.clearRect(0, 0, this.colorCanvas.width, this.colorCanvas.height)
		this.drawSquare();
		this.drawHue();
		// retrieving hex-code
		var hex = Colors.hsvToHex({
	    	h: this.hue,
	    	s: this.sat,
	    	v: this.val
		});
		// display hex string
		this.hexString.textContent = hex.toUpperCase();
		// display background color
		this.hexBox.style.backgroundColor = "#" + hex;
		document.getElementById("current_color").style.backgroundColor = "#" + hex;
		// arrow-selection
		var y = (this.hue / 362) * this.size - 2;
		this.colorCtx.drawImage(arrows, this.size + this.offset + 4, Math.round(y) + this.offset);
		// circle-selection
		var x = this.sat / 100 * this.size;
		var y = (1 - (this.val / 100)) * this.size;
		x = x - this.circle.width / 2;
		y = y - this.circle.height / 2;
		this.colorCtx.drawImage(this.circle, Math.round(x) + this.offset, Math.round(y) + this.offset);
		// run custom code
		if (this.callback) this.callback(hex);
    };

}

/* GLOBALS LIBRARY */

var dragElement = function(props) {
    function mouseMove(e, state) {
		if (typeof(state) == "undefined") state = "move";
		var coord = XY(e);
		switch (props.type) {
	    	case "difference":
				props.callback({
		    		x: coord.x + oX - eX,
		    		y: coord.y + oY - eY
				}, state);
				break;
	    	case "relative":
				props.callback({
		    		x: coord.x - oX,
		    		y: coord.y - oY
				}, state);
				break;
	    	default: // "absolute"
				props.callback({
		    		x: coord.x,
		    		y: coord.y
				}, state);
				break;
		}
    };
    function mouseUp(e) {
		//FIXME window.removeEventListener("mousemove", mouseMove, false);
		//FIXME window.removeEventListener("mouseup", mouseUp, false);
		mouseMove(e, "up");
    };
    // current element position
    var el = props.element;
    var origin = abPos(el);
    var oX = origin.x;
    var oY = origin.y;
    // current mouse position
    var e = props.event;
    var coord = XY(e);
    var eX = coord.x;
    var eY = coord.y;
    // events
    // window.addEventListener("mousemove", mouseMove, false);
    // window.addEventListener("mouseup", mouseUp, false);
    mouseMove(e, "down"); // run mouse-down
};

var clamp = function(n: number, min: number, max: number) {
    return (n < min) ? min : ((n > max) ? max : n);
};

var XY = function(event: {pageX: number, pageY: number}) {
	return {
	    x: event.pageX,
	    y: event.pageY
	};
};

var abPos = function(in_o: {offsetLeft: number, offsetTop: number, offsetParent: any}) {
    var o = typeof(in_o) == 'object' ? in_o : $(in_o);
    var offset = { x: 0, y: 0 };
    while(o != null) {
		offset.x += o.offsetLeft;
		offset.y += o.offsetTop;
		o = o.offsetParent;
    };
    return offset;
};

/* COLOR LIBRARY */

/* DEMO CODE */

// var swatch = document.getElementById("testSwatch");

/*
window.onload = function() {
    var picker = new Color.Picker({
	callback: function(hex) {
	    swatch.style.backgroundColor = "#" + hex;
	}
    });
    picker.el.style.top = (swatch.offsetTop) + "px";
    picker.el.style.left = (swatch.offsetLeft - 240) + "px";
};
 */
