Emplaitress {
    classvar <notes, <inverse, <groups, <lastAction;

    *initClass {
        notes = 6.collect { Dictionary.new};
		inverse = 6.collect {IdentityDictionary.new};
		lastAction = 0;
        
        StartUp.add {
			(Routine.new {
				10.yield;
				Server.default.sync;
	            groups = 6.collect { Group.new };        
    	        "ALL HAIL THE EMPLAITRESS".postln;
			}).play;
            SynthDef(\plaitsPerc, {
                |out, pitch=60.0, engine=0, harm=0.1, timbre=0.5, morph=0.5, fm_mod=0.0, timb_mod=0.0,
	    	        morph_mod=0.0, decay=0.5, lpg_color=0.5, mul=1.0, aux_mix=0.0, gain=1.0, pan=0.0, sendA=0, sendB=0, sendABus=0, sendBBus=0|
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
	    	    DetectSilence.ar(sound + Impulse.ar(0), amp: 0.0005, time: 0.1, doneAction: Done.freeSelf);
	    	    sound = (gain*sound).softclip;
				sound = Pan2.ar(sound, pan);
	    	    Out.ar(out, sound);
				Out.ar(sendABus, sendA*sound);
				Out.ar(sendBBus, sendB*sound);
	        }).add;
	        
            SynthDef(\plaitsADSR, {
                |out, pitch=60.0, engine=0, harm=0.1, timbre=0.5, morph=0.5, fm_mod=0.0, timb_mod=0.0,
	    	        morph_mod=0.0, attack=0.1, decay=0.5, sustain=0.5, release=0.5, lpg_color=0.5,
					mul=1.0, aux_mix=0.0, gain=1.0, pan=0.0, gate=1, pitch_lag=0.0, sendA=0, sendB=0, sendABus=0, sendBBus=0|
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
	    	    DetectSilence.ar(sound + Impulse.ar(0), amp: 0.0005, time: 0.1, doneAction: Done.freeSelf);
				sound = Pan2.ar(sound, pan);
	    	    Out.ar(out, sound);
				Out.ar(sendABus, sendA*sound);
				Out.ar(sendBBus, sendB*sound);				
	        }).add;	        

	    	OSCFunc.new({ |msg, time, addr, recvPort|
	    	    var args = [[\pitch, \engine, \harm, \timbre, \morph, \fm_mod, \timb_mod, \morph_mod, \decay, \lpg_color, \mul, \aux_mix, \gain, \pan, \sendA, \sendB], msg[1..]].lace;
	    	    Synth.new(\plaitsPerc, args);
	    	}, "/emplaitress/perc");
	    	OSCFunc.new({ |msg, time, addr, recvPort|
	    	    var voice = msg[1].asInteger;
	    	    var note = msg[2].asInteger;
	    	    var args = [[\pitch, \engine, \harm, \timbre, \morph, \fm_mod, \timb_mod, \morph_mod, \attack, \decay, \sustain, \release, \lpg_color, \mul, \aux_mix, \gain, \pan, \sendA, \sendB], msg[3..]].lace;
				var syn;
				(Routine {
				while({thisThread.clock.seconds - lastAction < 0.003}, {
					(0.001).yield;
				});
				// "on voice % group %, %\n".postf(voice, groups[voice], thisThread.clock.seconds);
				syn = Synth.new(
					\plaitsADSR, 
					args ++ [\sendABus, (~sendA ? Server.default.outputBus), \sendBBus, (~sendB ? Server.default.outputBus)], 
					target: groups[voice]);
				lastAction = thisThread.clock.seconds;
				syn.onFree({
					// 2-way dict bookeeping.
					var curNote;
					curNote = inverse[voice][syn];

					inverse[voice].removeAt(syn);
					if (notes[voice][curNote] === syn, {
						notes[voice].removeAt(curNote);
					});
				});
	    	    if (notes[voice].includesKey(note), {
					var toEnd = notes[voice][note];
	    	        toEnd.set(\gate, 0);
	    	    });

				// 2-way dict bookeeping.
	    	    notes[voice].put(note, syn);
				inverse[voice].put(syn, note);
				}).play;
	    	}, "emplaitress/note_on");
	    	OSCFunc.new({ |msg, time, addr, recvPort|			
	    	    var voice = msg[1].asInteger;
	    	    var note = msg[2].asInteger;
				var key = msg[3].asString.asSymbol;
				var val = msg[4].asFloat;
				// "% % % %\n".postf(voice, note, key, val);
	    	    if (notes[voice].includesKey(note), {
					var syn = notes[voice][note];
					//"modifying %\n".postf(syn.nodeID);
	    	        syn.set(key, val);
	    	    });			
	    	}, "emplaitress/note_simple_mod");			
	    	OSCFunc.new({ |msg, time, addr, recvPort|
	    	    var voice = msg[1].asInteger;
	    	    var note = msg[2].asInteger;
				var new_note = msg[3].asInteger;
	    	    var args = [[
					\pitch, \engine, \harm, \timbre, \morph, \fm_mod, 
					\timb_mod, \morph_mod, \attack, \decay, \sustain, 
					\release, \lpg_color, \mul, \aux_mix, \gain, \pan, \pitch_lag, \sendA, \sendB], 
					msg[4..]].lace;
				//"modify % to %\n".postf(note, new_note);
	    	    if (notes[voice].includesKey(note), {
					var syn = notes[voice][note];
					//"modifying %\n".postf(syn.nodeID);
	    	        syn.set(\gate, 1.0, *args);
					notes[voice].put(new_note, syn);
					if(note != new_note, {
						notes[voice].removeAt(note);
						inverse[voice].put(syn, new_note)
					});
	    	    }, {
					// Old voice has expired add new one.
					var syn = Synth.new(
						\plaitsADSR, 
						args ++ [\sendABus, (~sendA ? Server.default.outputBus), \sendBBus, (~sendB ? Server.default.outputBus)],
						target: groups[voice]);
					//"replacing with %\n".postf(syn.nodeID);
					syn.onFree({
						// 2-way dict bookeeping.
						var curNote;
						//"freed %".postf(syn.nodeID);
						curNote = inverse[voice][syn];

						inverse[voice].removeAt(syn);
						if (notes[voice][curNote] === syn, {
							notes[voice].removeAt(curNote);
						});
					});

					// 2-way dict bookeeping.
		    	    notes[voice].put(new_note, syn);
					inverse[voice].put(syn, new_note);
					});
	    	}, "emplaitress/note_mod");

			OSCFunc.new({|msg, time, addr, recvPort|
				notes.keysValuesDo {|voice, active|
					active.keysValuesDo {|note, syn|
						syn.set(\gate, 0);
						active.removeAt(note);
						inverse.removeAt(syn);
					};
				};
			}, "emplaitress/stop_all");
            OSCFunc.new({ |msg, time, addr, recvPort|
                var voice = msg[1].asInteger;
                var note = msg[2].asInteger;
				//"off %\n".postf(note);
                if (notes[voice].includesKey(note), {
					var cur = notes[voice][note];
					//"ending %s\n".postf(cur.nodeID);
                    notes[voice][note].set(\gate, 0);
                    //notes[voice].removeAt(note);
                });
            }, "/emplaitress/note_off");
        }
    }
}