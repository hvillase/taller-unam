//++++++++++++++++++++++++++++++++++++++++++++++//
// Introducción a la síntesis con SuperCollider //
// FaM UNAM 14 de marzo 2023                    //
// https://github.com/hvillase/taller-unam      //
//++++++++++++++++++++++++++++++++++++++++++++++//

//================================
// 1 Introducción a SuperCollider
//================================

"hola mundo".postln;

// esto es un comenatrio

() {} || [] ~ , ;

10
10.5
3 + 2
3 == 2
3 > 2
"palabras"


// Variables locales y globales

(
var adentro = 25;
adentro.value;
adentro + adentro;
);

adentro

a = 10;
a.value;

~afuera = 112.5678;
~afuera.value;
~afuera = "se pueden guardar palabras";
~afuera.value;

Server.help;

// Prender SuperCollider y ver formas de onda

s.boot;
s.scope;
s.freqscope;

// Formas de onda

{WhiteNoise.ar(0.1)!2}.play;
{PinkNoise.ar(0.1)!2}.play;
{SinOsc.ar(400,0,0.1)!2}.play;
{LFTri.ar(400,0,0.1)!2}.play;
{Saw.ar(400,0.1)!2}.play;
{Pulse.ar(400,0.5,0.1)!2}.play;

// apagar sonido botón de pánico
Ctrl + .

// audio y control
.ar
.kr

// Apagar el servidor
s.quit;

//=============
// 2 Síntesis
//=============

// SynthDef

SynthDef

// Envolvente
Env.help;

// 1 aditiva
(
SynthDef(\aditiva, {|f1=200, f2=300, f3=400, f4=500, a1=0.1, a2=0.1, a3=0.1, a4=0.1, amp=1, at=0.1,dec=0.1, sus=0.5, rel=1, gate=1, out=0|
	var sin1, sin2, sin3, sin4, pan, env;
	sin1=SinOsc.ar(f1, 0, a1);
	sin2=SinOsc.ar(f2, 0, a2);
	sin3=SinOsc.ar(f3, 0, a3);
	sin4=SinOsc.ar(f4, 0, a4);
	pan=Pan2.ar(sin1 + sin2 + sin3 + sin4, 0, amp);
	env= EnvGen.ar(Env([0,1,0.5,0.5,0], [at,dec,sus,rel]), gate, doneAction:2);
	Out.ar(out, pan * env)
}).add
)

Synth(\aditiva, [\f1, 254, \f2, 378, \f3, 450, \f4, 567, \at, 0.5, \sus,3, \rel, 1]);

// 2 sustractiva
(
SynthDef(\sustractiva, {|amp=0.1, fc=500, rq=1, gate=1, at=0.1, rel=0.1, out=0|
	var noise, pan, filtro, env;
	noise = WhiteNoise.ar(amp);
	pan = Pan2.ar(noise, 0);
	filtro = BPF.ar(pan, fc, rq);
	env=EnvGen.ar(Env([0, 1, 0],[at, rel]), gate, doneAction:2);
	Out.ar(out, filtro * env)
}).add
)

Synth(\sustractiva, [\rel, 3, \fc, 2000, \rq, 0.02, \amp, 0.5]);

// 3 síntesis por modulación am
(
SynthDef(\am, {|freq=400, modulador = 10, rel=1, amp=0.5, gate=1, out=0|
	var sen, pan, env;
	sen=SinOsc.ar(freq, 0, SinOsc.ar(modulador, 0, 0.2, 0.2));
	pan=Pan2.ar(sen, 0, amp);
	env=EnvGen.kr(Env([0,1,0],[0.1, rel]), gate, doneAction:2);
	Out.ar(out, pan * env)
}).add
)

Synth(\am, [\freq, 500, \modulador, 300, \rel, 1.5]);

// 4 síntesis por modulación fm
(
SynthDef(\fm, {|carrier = 250, modulador=2, index=10, amp=0.5, gate=1, out = 0|
	var sen, pan, env;
	sen=SinOsc.ar(carrier + SinOsc.ar(modulador, 0, index), 0, amp);
	pan=Pan2.ar(sen, 0);
	env=EnvGen.kr(Env([0, 1, 0],[0.1, 1]), gate, doneAction:2);
	Out.ar(out, pan * env)
}).add
)

Synth(\fm, [\carrier, 830, \modulador, 20, \index, 10, \amp, 0.2]);

// 5 sintesis wave shape
// crear un buffer para alojar una tabla de onda
~bch = Buffer.alloc(s, 1024, 1); // cheby
~bch.cheby(Array.series(8, 0.01, 0.03)); // creación de la tabla de amplitudes

(
SynthDef(\ws, {|freq = 300, aws = 0.5, pws = 0, atws = 0.1, rws = 0.1, ows = 0|
	var sen, env;
	sen = Shaper.ar(~bch, SinOsc.ar(freq, 0, aws));
	sen = Pan2.ar(sen, pws);
	env = EnvGen.kr(Env.perc(atws, rws), doneAction: 2);
	Out.ar(ows, sen * env);
}).add
);

Synth(\ws, [atws: 0.1, rws: 1]);

// Síntesis Karplus-Strong (modelado físico de cuerda pulsada)
// Secuencia con Demand
{Pluck.ar(PinkNoise.ar(0.5),Impulse.kr(3),440.reciprocal,440.reciprocal,10,0.1)}.play;

(
{
var arranqueEnv, atk = 0, dec = 0.001;
var arranque, delayTiempo, delayDecay = 0.5;
var notaMidi = 69; // A 440
delayTiempo = notaMidi.midicps.reciprocal;
//RandSeed.kr(Impulse.kr(1/delayDecay), 111);
arranqueEnv = EnvGen.kr(Env.perc(atk, dec), gate:
Impulse.kr(1/delayDecay));
arranque = PinkNoise.ar(arranqueEnv);
CombL.ar(arranque, delayTiempo, delayTiempo,
delayDecay, add: arranque);
}.play
);

(
SynthDef(\kp, {||
	var
}
).add
);

// sintesis granular
~bg = Buffer.read(s, "/usr/local/share/SuperCollider/sounds/a11wlk01.wav");

(
SynthDef(\GrainBuf,{|sndbuf,envbuf ,gate=1|
var sen, env, pan;
sen=GrainBuf.ar(1, Impulse.ar(10),0.1,sndbuf,LFNoise1.kr.range(1,2),LFNoise2.kr.range(0,1),1,0,envbuf)*4;
env=EnvGen.kr(Env.asr(1,1),gate,doneAction:2);
Out.ar(0,sen*env)
}).add
);

a=Synth(\GrainBuf);
a.set(\gate, 0);

// Tgrain

// Buffer con dos segundos de duración en mono
~bg2 = Buffer.alloc(s, s.sampleRate * 2, 1);

// luego hacemos un buffer para grabar sonido

(
SynthDef(\grabar,{|sen=0|
var entrada;
entrada=SoundIn.ar(sen);
RecordBuf.ar(entrada, ~bg2.bufnum);
}).add
);

x = Synth(\grabar);
x.free; // al declarar esta linea se queda un sonido en el buffer

// reproducimoslo grabado
(
SynthDef(\reproducir,{|salida=0|
var senal;
senal=PlayBuf.ar(1, ~bg2.bufnum,1);
Out.ar(salida,senal!2)
}).add
);

y=Synth(\reproducir);

// granulamos el buffer con TGrains, usamos BufDur para saber la duración del buffer

(
SynthDef(\Tgrains,{|salida=0, buffer=0|
var senal;
senal=TGrains.ar(2,Impulse.ar(26),~bg2.bufnum,1,MouseX.kr(0,BufDur.kr(~bg2.bufnum)),0.1,0,1,2);
Out.ar(0,senal!2)
}).add
);

w=Synth(\Tgrains);
w.free;

// Secuencia

(
Pdef(\sintesis, Pbind(\instrument, \aditiva,
	\dur, Pseq([0.5, 1.05, 0.25, 0.75], inf),
	\f1, Pseq([340, 460, 500], inf),
	\f2, Pseq([550, 650, 670], inf),
	\f3, Pseq([700, 800, 1230, 1500], inf),
	\amp, 0.3
)).stop
);

(
Pdef(\sintesis, Pbind(\instrument, \sustractiva,
	\dur, Pseq([0.5, 1, 0.25], inf),
	\fc, Pseq([500, 200, 1000], inf),
	\amp, 0.4
)).stop
);

(
Pdef(\sintesis, Pbind(\instrument, \am,
	\dur, Pseq([0.5, 1, 0.25], inf),
	\freq, Pseq([500, 200, 800], inf),
	\modulador, Pseq([20, 40, 8, 10, 5], inf),
	\amp, 0.2
)).stop
);

(
Pdef(\sintesis, Pbind(\instrument, \fm,
	\dur, Pseq([0.5, 1, 0.25, 0.5, 1], inf),
	\carrier, Pseq([500, 200, 1000, 300, 200], inf),
	\modulador, Pseq([20, 9, 50],inf),
	\amp, 0.1
)).stop
);

// Grabación
// Presionar Start Recording en el cuadro de la esquina inferior derecha
// Buscar la ruta de los sonidos
Platform.recordingsDir;

//===========================+
// Hernani Villaseñor 2023   +
// hernani.vr@gmail.com      +
// www.hernanivillasenor.com +
//===========================+