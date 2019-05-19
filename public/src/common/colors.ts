
const BASE_HUE = 180;

export interface RGBColor {
	r: number;
	g: number;
	b: number;
}

export interface HSVColor {
	h: number;
	s: number;
	v: number;
}

export type HexColor = string;

export type Color = HexColor | RGBColor | HSVColor;

/**
 * Returns the 'str_number' string in parameter
 * left-padded with 'len' zeros.
 */
function padString(str_number: string, len: number): string {
	var padd_len = len - str_number.length;
	if (padd_len > 0) {
		return [padd_len + 1].join('0') + str_number;
	}
	return str_number;
};

export function RGBToHex (c: RGBColor): string {
	return padString(c.r.toString(16), 2) +
		padString(c.g.toString(16), 2) +
		padString(c.b.toString(16), 2);
};

export function HSVToHex(c: HSVColor) {
	return RGBToHex(HSVToRGB(c));
}


/**
 * HSV to RGB color conversion
 *
 * H runs from 0 to 360 degrees
 * S and V run from 0 to 100
 *
 * Ported by Roshambo from the excellent java algorithm by Eugene Vishnevsky at:
 * http://www.cs.rit.edu/~ncs/color/t_convert.html
 */
export function HSVToRGB(c: HSVColor) {
	var r, g, b, 
		h, s, v,
		i, f, p, q, t;

	// Make sure our arguments stay in-range
	h = Math.max(0, Math.min(360, c.h));
	s = Math.max(0, Math.min(100, c.s));
	v = Math.max(0, Math.min(100, c.v));

	// We accept saturation and value arguments from 0 to 100 because that's
	// how Photoshop represents those values. Internally, however, the
	// saturation and value are calculated from a range of 0 to 1. We make
	// That conversion here.
	s /= 100;
	v /= 100;

	if (s === 0) {
		// Achromatic (grey)
		r = g = b = v;
		return {
			r: Math.round(r * 255), 
			g: Math.round(g * 255), 
			b: Math.round(b * 255)
		};
	}

	h /= 60; // sector 0 to 5
	i = Math.floor(h);
	f = h - i; // factorial part of h
	p = v * (1 - s);
	q = v * (1 - s * f);
	t = v * (1 - s * (1 - f));

	switch (i) {
		case 0:
			r = v;
			g = t;
			b = p;
			break;
		case 1:
			r = q;
			g = v;
			b = p;
			break;
		case 2:
			r = p;
			g = v;
			b = t;
			break;
		case 3:
			r = p;
			g = q;
			b = v;
			break;
		case 4:
			r = t;
			g = p;
			b = v;
			break;
		default: // case 5:
			r = v;
			g = p;
			b = q;
	}

	return {
		r: Math.round(r * 255), 
		g: Math.round(g * 255), 
		b: Math.round(b * 255)
	};
};

export function randomHex() {
	return "#" + randomRGB();
}

export function randomRGB() {
	var c;
	c = randomHSV();
	return HSVToRGB(c);
}

export function randomHSV() : HSVColor {
	var hue, sat, val;
	hue = Math.floor(Math.random() * 360) + 1;
	sat = 80 + Math.floor(Math.random() * 20);
	val = 25 + Math.floor(Math.random() * 75);

	return {h: hue, s: sat, v: val};
}

