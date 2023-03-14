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

//==============================
// 2 Introducción a la Síntesis
//==============================

// SynthDef

SynthDef

// Envolvente
Env.help;

//++++++++++++++++++++++
// 2.1 Síntesis Aditiva
//++++++++++++++++++++++

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

//++++++++++++++++++++++++++
// 2.2 Síntesis Sustractiva
//++++++++++++++++++++++++++

(
SynthDef(\sustractiva, {|amp=0.1, fc=500, rq=1, gate=1, at=0.1, rel=0.1, out=0|
	var noise, pan, filtro, env;
	noise = WhiteNoise.ar(amp);
	pan = Pan2.ar(noise, 0);
	filtro = BPF.ar(pan, fc, rq);
	env=EnvGen.ar(Env([0, 1, 0],[at, rel]), gate, doneAction:2);
	Out.ar(out, filtro * env)
}).add
);

Synth(\sustractiva, [\rel, 3, \fc, 2000, \rq, 0.02, \amp, 0.5]);

//+++++++++++++++++++++++++++++++++
// 2.3 Síntesis por modulación am
//+++++++++++++++++++++++++++++++++

(
SynthDef(\am, {|freq=400, modulador = 10, rel=1, amp=0.5, gate=1, out=0|
	var sen, pan, env;
	sen=SinOsc.ar(freq, 0, SinOsc.ar(modulador, 0, 0.2, 0.2));
	pan=Pan2.ar(sen, 0, amp);
	env=EnvGen.kr(Env([0,1,0],[0.1, rel]), gate, doneAction:2);
	Out.ar(out, pan * env)
}).add
);

Synth(\am, [\freq, 500, \modulador, 300, \rel, 1.5]);

//+++++++++++++++++++++++++++++++++
// 2.4 Síntesis por modulación fm
//+++++++++++++++++++++++++++++++++

(
SynthDef(\fm, {|carrier = 250, modulador=2, index=10, amp=0.5, gate=1, out = 0|
	var sen, pan, env;
	sen=SinOsc.ar(carrier + SinOsc.ar(modulador, 0, index), 0, amp);
	pan=Pan2.ar(sen, 0);
	env=EnvGen.kr(Env([0, 1, 0],[0.1, 1]), gate, doneAction:2);
	Out.ar(out, pan * env)
}).add
);

Synth(\fm, [\carrier, 500, \modulador, 200, \index, 600, \amp, 0.2]);

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// 2.5 Síntesis Modelado de Onda (wave shape o waveshaping)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// Crear un buffer para alojar una tabla de onda de amplitudes con cheby
~bch = Buffer.alloc(s, 1024, 1);
~bch.cheby(Array.series(8, 0.01, 0.03));

// usar el UGen Shaper
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

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// 2.6 Síntesis Karplus-Strong (modelado físico de cuerda pulsada)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

(
SynthDef(\pluck, {|nota=200, imp=3, amp=1|
	var pk, pan;
	pk = Pluck.ar(PinkNoise.ar(0.5),Impulse.kr(imp),nota.reciprocal,nota.reciprocal,10,0.1);
	pan = Pan2.ar(pk, 0, amp);
	Out.ar(0, pan);
}).add
);

~pk=Synth(\pluck);
~pk.set(\nota, 200, \imp, 2);
~pk.free;

//+++++++++++++++++++++++
// 2.7 Síntesis granular
//+++++++++++++++++++++++

~bg = Buffer.read(s, "/usr/local/share/SuperCollider/sounds/a11wlk01.wav");

(
SynthDef(\GrainBuf,{|sndbuf, envbuf, pn = 0, amp=1,  gate=1|
var sen, env, pan;
	sen=GrainBuf.ar(1, Impulse.ar(10),0.1,sndbuf,LFNoise1.kr.range(1,2),LFNoise2.kr.range(0,1),1,0,envbuf)*4;
	pan=Pan2.ar(sen, pn, amp);
	env=EnvGen.kr(Env.asr(1, 1),gate,doneAction:2);
Out.ar(0, pan*env)
}).add
);

a=Synth(\GrainBuf);
a.set(\gate, 0);

// Tgrain
// granulamos el sonido leído por el buffer con TGrains
~bg2 = Buffer.read(s, "/usr/local/share/SuperCollider/sounds/a11wlk01.wav");

(
SynthDef(\Tgrains, {|pan = 0, amp = 1,  out = 0|
var senal, paneo;
	senal=TGrains.ar(~bg2.numChannels, Impulse.ar(26),~bg2.bufnum,1,MouseX.kr(0, BufDur.kr(~bg2.bufnum)), 0.1, 0, 1, 2);
	paneo = Pan2.ar(senal, pan, amp);
Out.ar(out, paneo)
}).add
);

w=Synth(\Tgrains);
w.free;

// Tgrains coin sampletexto

SampleTexto.help;
t=SampleTexto.new;
t.init(path: "/sonotexto");
t.stsel;
t.stm(0).play;

(
~num=0;
SynthDef(\TgrainsST, {|pan = 0, amp = 1,  out = 0|
var senal, paneo;
	senal=TGrains.ar(t.stm(~num).numChannels, Impulse.ar(20), t.stm(~num).bufnum,1,MouseX.kr(0, BufDur.kr(t.stm(~num).bufnum)), 0.1, 0, 1, 2);
	paneo = Pan2.ar(senal, pan, amp);
Out.ar(out, paneo)
}).add
);

z=Synth(\TgrainsST);
z.free;

//===========================
// 3 Secuencia con patrones
//===========================

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
	\carrier, Pseq([500, 200, 1000, 300, 200, 500], inf),
	\modulador, Pseq([200, 900, 500],inf),
	\index, 600,
	\amp, 0.1
)).stop
);

(
Pdef(\sintesis, Pbind(\instrument, \ws,
	\dur, 0.25,
	\freq, Pseq([250, 300, 440, 170, 500, 170, 550].mirror, inf),
	\rws, 0.5
)).stop
);

//=============
// 4 Grabación
//=============

// Presionar Start Recording en el cuadro de la esquina inferior derecha
// Buscar la ruta de los sonidos
Platform.recordingsDir;

//===========================+
// Hernani Villaseñor 2023   +
// hernani.vr@gmail.com      +
// www.hernanivillasenor.com +
//===========================+