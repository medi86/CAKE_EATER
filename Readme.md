Network Games
=============

I was introduced to [Karel the robot](https://en.wikipedia.org/wiki/Karel_(programming_language),
and liked it quite a bit. However, it's based in Java and I'm teaching Ruby (not a problem, except
that I want something for very new beginners, so giving them 2 languages, and trying to explain
types to them seems difficult), and I struggled for quite a while getting the environment to work
properly, and I felt like the goal was a little ambiguous.

So, this is an attempt to do something similar (differs in terms of goal and pedagogy, but similar
in terms of the environment). It would be a game that they can join and play by creating a client
to talk to it through HTTP. I'd give them the code to send HTTP requests, and then they could
just play with it in the console, or they could build some abstractions. This part should be
within their reach, because we're starting out with JSON data structures, and after I magic away
how to talk through HTTP, they would just be left with a visual on the screen and a bunch of
hashes and arrays and things.


Games
-----

Currently there is only one game, "Cake Eater". The goal is to run around the board discovering cake
and then eating it, obviously. If I get it to a usable point and they enjoy it, then more may come.


State
-----

Currently it is playable, but not visualizable. I'm doing visualizations with JavaScript
through websockets, but this is all pretty out of my league at the moment.
Hoping to have something playable by the end of the week so that we can have fun with it.
