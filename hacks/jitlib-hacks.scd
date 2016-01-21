
/*

here a few hints of how you can combine tidal and jitlib

note that you can always rewrite SynthDefs on the fly that tidal uses, so this isn't covered here.

There is one example of how to hack core effects and combine them with Ndef. This can also be done with ProxySpace of course.


Notice that in general, it is equivalent:

Ndef(\x, { PinkNoise.ar }).play

with:

p = ProxySpace.push(s.boot); // as preparation
~x = { PinkNoise.ar };
~x.play;

If you want to use ProxySpace.push, however, you have to modify your startup file a little, not to use the environment keys.

The following examples assume that you have stored an instance of SuperDirt in ~dirt
(see superdirt_sartup.scd)


*/


// getting tidal output into node proxies

Ndef(\dirty).ar(~dirt.numChannels); // make a place for a signal
~dirt.dirtBusses.do { |each| each.outBus = Ndef(\dirty).bus };

// now tidal should be silently playing in Ndef(\dirty).

// listen directly:

Ndef(\dirty).play;

// stop listening

Ndef(\dirty).stop;

// use output in other Ndefs

Ndef(\x, { RLPF.ar(Ndef.ar(\dirty), MouseX.kr(300, 8000, 1), 0.04) }).play; // etc.


// go back to normal:
~dirt.dirtBusses.do { |each| each.outBus = 0; };


/*

using SuperDirt from sclang patterns

*/

(
var d = ~dirt.dirtBusses.first;
Event.addEventType(\dirt, {
	~latency = s.latency;
	d.value(currentEnvironment.asPairs)
})
)

(
Pdef(\x,
	Pbind(
		\type, \dirt,
		\s, Prand([\bd, \hh, \cp, ], inf),
		\begin, Pn(Pseries(0, 0.002, 20))
		\dur, 0.2,
	)
).play;
)

(
var keys = ~dirt.buffers.keys;
Pdef(\x,
	Pbind(
		\type, \dirt,
		\s, Pfunc { keys.choose },
		\speed, Pfunc { rrand(1.0, 2) * [1, 1, 1, -1].choose },
		\dur, Pseq([1, 1/2, 1/2, 1, 1/3, 2/3, 1/2, 1/8], inf)
	)
).play;
)



/*

drive a stream from tidal

*/

(
q = ();
SynthDef('next', { }).add; // dummy
~dirt.addModule('sync', {
	s.latency = ~latency;
	q[\func].value;
}, { ~instrument == \next });
)


/*
send from tidal:

d1 $ sound "hh next"

*/


// now try with some pattern
(
var stream = Pevent(Pdef(\x)).asStream;
q[\func] = { stream.next }
)

// hook some pattern in
Pdef(\x, Pbind(\degree, Pseq([0, 5, -3, 6, -2, [0, 5, 6]], inf), \sustain, 0.1)).play;
Pdef(\x, Pbind(\freq, rrand(6000, 7000) + Pseq((10, 20..400) *.t (1.1, 1.2 ..2), inf), \sustain, 0.1)).play;


/*

clock sync
this is a hack that doesn't yet work. Proper clock sync would require a bit of tinkering on both sides

*/

(
q = ();
q[\synched] = false;
SynthDef('sync', { }).add; // dummy
~dirt.addModule('sync', {
	if(q[\synched].not) {
		"-------- new tempo clock started --------".postln;
		TempoClock.default = TempoClock.new(~cps).permanent_(true);
		q[\synched] = true;
	};
	s.latency = ~latency;
	/*
	// this doesn't work, because the clock has changed in tidal already at another moment.
	if(~cps != TempoClock.default.tempo) {
			TempoClock.default.tempo = ~cps;
			"tempo set to %\n".postf(~cps);
	};
	*/
}, { ~instrument == \sync });
)

/*
send from tidal:

d1 $ sound "hh sync"

*/


// now try with some pattern

Pdef(\x).quant = 1.0;
Pdef(\x, Pbind(\freq, rrand(6000, 7000) + Pseq((10, 20..400) *.t (1.1, 1.2 ..2), inf), \sustain, 0.1, \dur, 0.5)).play;



