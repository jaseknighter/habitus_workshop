Engine_Habitus_poll : CroneEngine {
	var kernel, debugPrinter;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		kernel = Habitus_poll.new(Crone.server);

		// NEW: 'amp' now has a string argument, to target a specific channel:
		this.addCommand(\amp, "sf", { arg msg;
			var side = msg[1].asString, amp = msg[2].asFloat;
			kernel.setAmp(side, amp);
		});

		// NEW: polls are monophonic, so we'll set one up for each channel:
		this.addPoll(\outputAmpL, {
			// NEW: 'getSynchronous' lets us query a SuperCollider variable from Lua!
			var ampL = kernel.amplitude[0].getSynchronous;
			ampL
		});

		this.addPoll(\outputAmpR, {
			var ampR = kernel.amplitude[1].getSynchronous;
			ampR
		});

		// debugPrinter = { loop { [context.server.peakCPU, context.server.avgCPU].postln; 3.wait; } }.fork;
	}

	free {
		kernel.free;
		// debugPrinter.stop;
	}
}