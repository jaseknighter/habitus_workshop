Habitus_poll {

	var <passthrough;
	var <amplitude; // NEW: we want to query our outgoing amplitude from norns, so we'll make this a 'getter'

	*initClass {

		StartUp.add {
			var s = Server.default;

			// we need to make sure the server is running before asking it to do anything
			s.waitForBoot {

				// define a simple 'input multiplied by amplitude value' synth called 'inOutAmp':
				SynthDef(\inOutAmp, {
					// NEW: we're giving each channel of incoming audio its own amp value:
					arg ampL = 1, ampR = 1, levelOutL, levelOutR;
					var soundL, soundR, ampTrackL, ampTrackR;

					soundL = SoundIn.ar(0);
					soundR = SoundIn.ar(1);
					ampTrackL = Amplitude.kr(in: soundL * ampL);
					ampTrackR = Amplitude.kr(in: soundR * ampR);

					Out.ar(0, [soundL * ampL, soundR * ampR]);
					// NEW:
					// we send the amplitude of each channel, after adjustment, to a control bus:
					Out.kr(levelOutL, ampTrackL);
					Out.kr(levelOutR, ampTrackR);
				}).add;

			} // s.waitForBoot
		} // StartUp
	} // *initClass

	*new {
		^super.new.init;
	}

	init {
		var s = Server.default;

		// NEW:
		// we'll build an 'amplitude' array of control busses, one for each channel:
		amplitude = Array.fill(2, { arg i; Bus.control(s); });

		passthrough = Synth.new(\inOutAmp, [
			\ampL, 1,
			\ampR, 1,
			// NEW:
			// we'll assign the outgoing level values to each channel's amplitude array entry:
			\levelOutL, amplitude[0].index,
			\levelOutR, amplitude[1].index,
		]);

		s.sync;
	} // init

	// NEW: set each channel inividually
	setAmp { arg side, amp;
		passthrough.set(\amp++side, amp);
	}

	// IMPORTANT!
	// free our processes after we're done with the engine:
	free {
		passthrough.free;
		// NEW: free our control busses!
		amplitude.do({ arg bus; bus.free; });
	} // free

}