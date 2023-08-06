HabitusPoll {

	// instantiate variables here
	var <passthrough;
	// we want 'passthrough' to be accessible any time we instantiate this class,
	// so we prepend it with '<', to turn it into a 'getter' method.
	// see 'Getters and Setters' at https://doc.sccode.org/Guides/WritingClasses.html for more info.
	var <amplitude; // we want to query our outgoing amplitude from norns, so we'll make this a 'getter'

	// in SuperCollider, asterisks denote functions which are specific to the class.
	// '*initClass' will be called when the 'Habitus' class is initialized, at boot.
	// see https://doc.sccode.org/Classes/Class.html#*initClass for more info.
	*initClass {

		StartUp.add {
			var s = Server.default;

			// we need to make sure the server is running before asking it to do anything
			s.waitForBoot {
				// we don't need to do anything!
			} // s.waitForBoot
		} // StartUp
	} // *initClass

	// when our Engine_HabitusPoll.sc file creates its synth...
	*new {
		^super.new.init;  // ...run the 'init' below.
	}

	init {
		var s = Server.default;

		// we'll build an 'amplitude' array of control busses, one for each channel:
		amplitude = Array.fill(2, { arg i; Bus.control(s); });

		// define a simple 'input multiplied by amplitude value' synth called 'inOutAmp':
		SynthDef(\inOutAmp, {
			// we're giving each channel of incoming audio its own amp value:
			arg ampL = 1, ampR = 1, levelOutL, levelOutR;
			var soundL, soundR, ampTrackL, ampTrackR;

			soundL = SoundIn.ar(0);
			soundR = SoundIn.ar(1);
			ampTrackL = Amplitude.kr(in: soundL * ampL);
			ampTrackR = Amplitude.kr(in: soundR * ampR);

			Out.ar(0, [soundL * ampL, soundR * ampR]);
			// we send the amplitude of each channel, after adjustment, to a control bus:
			Out.kr(levelOutL, ampTrackL);
			Out.kr(levelOutR, ampTrackR);
		}).add;

		// create 'passthrough' using the 'inOutAmp' SynthDef:
		passthrough = Synth.new(\inOutAmp, [
			\ampL, 1,
			\ampR, 1,
			// we'll assign the outgoing level values to each channel's amplitude array entry:
			\levelOutL, amplitude[0].index,
			\levelOutR, amplitude[1].index,
		]);

		s.sync; // sync the changes above to the server
	} // init

	// create a command to set each channel individually
	setAmp { arg side, amp;
		passthrough.set(\amp++side, amp);
	}

	// IMPORTANT!
	// free our processes after we're done with the engine:
	free {
		passthrough.free;
		// free our control busses!
		amplitude.do({ arg bus; bus.free; });
	} // free

}