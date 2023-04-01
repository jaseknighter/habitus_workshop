Engine_HabitusPassthrough : CroneEngine {
	var kernel, debugPrinter;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		kernel = HabitusPassthrough.new(Crone.server);

		this.addCommand(\amp, "f", { arg msg;
			var amp = msg[1].asFloat;
			kernel.setAmp(amp);
		});

		// debugPrinter = { loop { [context.server.peakCPU, context.server.avgCPU].postln; 3.wait; } }.fork;
	}

	free {
		kernel.free;
		// debugPrinter.stop;
	}
}