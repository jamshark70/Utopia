////////////////////////
// decentralised discovery of participants
// find who's on the network
(
~win = Window("AdHocSociety").front;
~win.layout = VLayout.new.add(~listView = ListView.new);

~addrBook = AddrBook.new;
// to get updates, just add a dependant
~addrBook.addDependant({|addrBook, what, who|
	{~listView.items = addrBook.citizens.collectAs({|cit|
		cit.name ++ " | " ++ cit.addr.ip ++ " | " ++ if(cit.online, "online", "offline");
	}, Array)}.defer;
});

~addrBook.addMe;

~attendance = Attendance(~addrBook);
)

//fake another participant
~attendance2 = Attendance(me: OSCitizen(\me2, NetAddr.localAddr, s.addr));

// \me2 goes offline
~attendance2.free;

//cleanup
~attendance.free; ~win.close;



////////////////////////
// Equivalent example using Registrar (centralised registration)
(
~win = Window("Benevolent Dictatorship").front;
~win.layout = VLayout.new.add(~listView = ListView.new);

~addrBook = AddrBook.new;
// to get updates, just add a dependant
~addrBook.addDependant({|addrBook, what, who|
	{~listView.items = addrBook.citizens.collectAs({|cit|
		cit.name ++ " | " ++ cit.addr.ip ++ " | " ++ if(cit.online, "online", "offline");
	}, Array)}.defer;
});

~addrBook.addMe;

~registrar = Registrar(); // this could be running on a separate computer or in a separate process
~registrant = Registrant(~addrBook);
)

//fake another participant
~registrant2 = Registrant(me: OSCitizen(\me2, NetAddr.localAddr, s.addr));

// \me2 goes offline
~registrant2.free;

//cleanup
~registrant.free; ~registrar.free; ~win.close;


////////////////////////
// Chatter, one of a number of classes which relay data to members of an AddrBook

// make some citizens and address books
(
thisProcess.openUDPPort(3000);
~cit1 = OSCitizen(\me1, NetAddr.localAddr, s.addr);
~cit2 = OSCitizen(\me2, NetAddr("127.0.0.1", 3000), s.addr); // I'll use a different port and simulate a different machine
~addrBook1 = AddrBook().addMe(~cit1);
~addrBook2 = AddrBook().addMe(~cit2);
~addrBook1.add(~cit2);
~addrBook2.add(~cit1);
)

~chatter1 = Chatter(~addrBook1, false);
~chatter2 = Chatter(~addrBook2);

~chatter1.send("howdy");
~chatter1.sendPrivate(\me2, "Psst... howdy!"); // send only to \me2

// make a GUI for cit1
(
~win = Window("Chatty Betty").front;
~win.layout = VLayout(~textField = TextField(), ~textView = TextView());
~textField.action_({|v| ~chatter1.send(v.string); v.string = "" });
// to get updates, just add a dependant
~chatter1.addDependant({|chatter, what, who, chat|
	{ ~textView.string_(who ++ ": " ++ chat ++ "\n" ++ ~textView.string) }.defer;
});
)

~chatter2.send("Works from me too");

// cleanup
~chatter1.free; ~chatter2.free;


////////////////////////
// A very dumb clock example to show how you might integrate a clock with this
// Master and slave clocks must share a common time base, e.g. using the NTP class
// Ticks are scheduled with a small latency, so as to avoid drift

// make some citizens and address books
(
thisProcess.openUDPPort(3000);
~cit1 = OSCitizen(\me1, NetAddr.localAddr, s.addr);
~cit2 = OSCitizen(\me2, NetAddr("127.0.0.1", 3000), s.addr); // I'll use a different port and simulate a different machine
~addrBook = AddrBook();
~addrBook.add(~cit1);
~addrBook.add(~cit2);
)

// make some slaves first, then the master. They only advance when master ticks, so they should stay aligned
(
~slave1 = SlaveClock(NetAddr.localAddr);
~slave2 = SlaveClock(NetAddr.localAddr);
)
~master = MasterClock(~addrBook); // add a master which starts ticking, this would probably be on a different machine or process

~slave1.sched(1, {\foo.postln}); SystemClock.sched(1, {\bar.postln});

Pbind(\degree, Pseq((1..4), inf)).play(~slave1); Pbind(\degree, Pseq((5..8), inf)).play(~slave2);
~master.tempo = 3;

Pbind(\degree, Pseq((2..5), inf), \dur, 3, \octave, 6).play(~slave2);

~slave1.beats.postln; ~slave2.beats.postln; // these will be the same