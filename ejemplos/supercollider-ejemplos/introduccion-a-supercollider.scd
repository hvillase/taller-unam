"hola mundo".postln

// comenatrio
() {} || ~

s.boot;// prender supercollider

{WhiteNoise.ar(0.05)!2}.play;
{SinOsc.ar(400,0,0.05)!2}.play;
{LFTri.ar(400,0,0.05)!2}.scope;
{Saw.ar(400,0.05)!2}.scope;
{Pulse.ar(400,0.5,0.05)!2}.scope;

// apagar sonido botón de pánico
Ctrl + .

