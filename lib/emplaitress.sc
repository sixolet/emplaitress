Emplaitress {
    classvar <notes, <groups;

    *initClass {
        notes = 6.collect { Dictionary.new};
        
        StartUp.add {
            groups = 6.collect { Group.new(server: Server.default) };        
            "ALL HAIL THE EMPLAITRESS".postln;
            SynthDef(\plaitsPerc, {
                |out, pitch=60.0, engine=0, harm=0.1, timbre=0.5, morph=0.5, fm_mod=0.0, timb_mod=0.0,
	    	        morph_mod=0.0, decay=0.5, lpg_color=0.5, mul=1.0, aux_mix=0.0, gain=1.0, pan=0.0|
	    	    var sound = MiPlaits.ar(
	    	            pitch: pitch, 
	    	            engine: engine, 
	    	            harm: harm, 
	    	            timbre: timbre, 
	    	            morph: morph,
	    	            trigger: Impulse.kr(0),
	    	            fm_mod: fm_mod,
	    	            timb_mod: timb_mod, 
	    	            morph_mod: morph_mod, 
	    	            decay: decay, 
	    	            lpg_colour: lpg_color, 
	    	            mul: mul);
	    	    sound = SelectX.ar(aux_mix, sound);
	    	    sound = LeakDC.ar(sound);
	    	    DetectSilence.ar(sound, amp: 0.0005, time: 0.1, doneAction: Done.freeSelf);
	    	    sound = (gain*sound).softclip;
	    	    Out.ar(out, Pan2.ar(sound, pan));
	        }).add;
	        
            SynthDef(\plaitsADSR, {
                |out, pitch=60.0, engine=0, harm=0.1, timbre=0.5, morph=0.5, fm_mod=0.0, timb_mod=0.0,
	    	        morph_mod=0.0, attack=0.1, decay=0.5, sustain=0.5, release=0.5, lpg_color=0.5,
					mul=1.0, aux_mix=0.0, gain=1.0, pan=0.0, gate=1, pitch_lag=0.0|
	    	    var env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction: Done.none);
	    	    var sound = MiPlaits.ar(
	    	            pitch: pitch.lag(pitch_lag), 
	    	            engine: engine, 
	    	            harm: harm, 
	    	            timbre: timbre + (timb_mod*env), 
	    	            morph: morph + (morph_mod*env),
	    	            level: env,
	    	            fm_mod: fm_mod,
	    	            lpg_colour: lpg_color, 
	    	            mul: mul);
	    	    sound = SelectX.ar(aux_mix, sound);
	    	    sound = LeakDC.ar(sound);
	    	    sound = OnePole.ar(sound, coef: (1 - env)*(1 - lpg_color));
	    	    sound = (gain*sound).softclip;
	    	    DetectSilence.ar(sound, amp: 0.0005, time: 0.1, doneAction: Done.freeSelf);
	    	    Out.ar(out, Pan2.ar(sound, pan));
	        }).add;	        

	    	OSCFunc.new({ |msg, time, addr, recvPort|
	    	    var args = [[\pitch, \engine, \harm, \timbre, \morph, \fm_mod, \timb_mod, \morph_mod, \decay, \lpg_color, \mul, \aux_mix, \gain, \pan], msg[1..]].lace;
	    	    Synth.new(\plaitsPerc, args);
	    	}, "/emplaitress/perc");
	    	OSCFunc.new({ |msg, time, addr, recvPort|
	    	    var voice = msg[1].asInteger;
	    	    var note = msg[2].asInteger;
	    	    var args = [[\pitch, \engine, \harm, \timbre, \morph, \fm_mod, \timb_mod, \morph_mod, \attack, \decay, \sustain, \release, \lpg_color, \mul, \aux_mix, \gain, \pan], msg[3..]].lace;
	    	    if (notes[voice].includesKey(note), {
	    	        notes[voice][note].set(\gate, 0);
	    	    });
	    	    notes[voice].put(note, Synth.new(\plaitsADSR, args, target: groups[voice]));
	    	}, "emplaitress/note_on");
	    	OSCFunc.new({ |msg, time, addr, recvPort|
	    	    var voice = msg[1].asInteger;
	    	    var note = msg[2].asInteger;
				var new_note = msg[3].asInteger;
	    	    var args = [[
					\pitch, \engine, \harm, \timbre, \morph, \fm_mod, 
					\timb_mod, \morph_mod, \attack, \decay, \sustain, 
					\release, \lpg_color, \mul, \aux_mix, \gain, \pan, \pitch_lag], 
					msg[4..]].lace;
				//args.postln;
				//msg[4].asFloat.postln;
	    	    if (notes[voice].includesKey(note), {
					"setting".postln;
					// notes[voice][note].set(\pitch, msg[4].asFloat);
	    	        notes[voice][note].set(*args);
					notes[voice].put(new_note, notes[voice][note]);
					if(note != new_note, {
						notes[voice].removeAt(note);
					});
	    	    });
	    	}, "emplaitress/note_mod");
            OSCFunc.new({ |msg, time, addr, recvPort|
                var voice = msg[1].asInteger;
                var note = msg[2].asInteger;
                if (notes[voice].includesKey(note), {
                    notes[voice][note].set(\gate, 0);
                    notes[voice].removeAt(note);
                });
            }, "/emplaitress/note_off");
        }
    }
}