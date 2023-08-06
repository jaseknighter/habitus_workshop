HabitusPassthrough {

	// instantiate variables here
	var <passthrough;
	// we want 'passthrough' to be accessible any time we instantiate this class,
	// so we prepend it with '<', to turn it into a 'getter' method.
	// see 'Getters and Setters' at https://doc.sccode.org/Guides/WritingClasses.html for more info.

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

	// when our Engine_HabitusPassthrough.sc file creates its synth...
	*new {
		^super.new.init;  // ...run the 'init' below.
	}

	init {
		var s = Server.default;

		// define a simple 'input multiplied by amplitude value' synth called 'inOut':
		SynthDef(\inOut, {
			arg amp = 1;
			var sound;

			sound = SoundIn.ar([0,1]);

			Out.ar(0, sound * amp);
		}).add;

		// create 'passthrough' using the 'inOut' SynthDef:
		passthrough = Synth.new(\inOut, [
			\amp, 1
		]);

		s.sync; // sync the changes above to the server
	}

	// create a command to control the synth's 'amp' value:
	setAmp { arg amp;
		passthrough.set(\amp, amp);
	}

	// IMPORTANT!
	// free our synth after we're done with it:
	free {
		passthrough.free;
	}

}