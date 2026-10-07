---
title: ODIN
tagline: A tutoring system disguised as a dungeon crawler.
gallery:
  - src: ../../assets/projects/odin/logo.png
    alt: The ODIN logo, a pixel-art robot face
  - src: ../../assets/projects/odin/battle.png
    alt: ODIN's battle screen, with a code editor next to the player character
stack: [Godot 4, GDScript, ASP.NET Core 8, PostgreSQL, React]
play: https://insomnicode-odin.vercel.app
source: https://github.com/russellmagdaong/odin-game
order: 1
---

ODIN is my undergraduate thesis, built with three teammates as InsomniCode. It teaches C# arrays through a pixel-art RPG: you walk a dungeon, run into an enemy, and win the fight by writing real code in an in-game editor.

The interesting part is what happens after you hit submit. The game records how you typed (pauses, bursts, how much you changed between attempts) and sends it with your code to an ASP.NET Core backend. Roslyn parses the code to find the specific misconception, such as an off-by-one loop bound, and Bayesian Knowledge Tracing estimates how well you know the skill. The typing data tells a student who is thinking apart from one who is guessing or stuck, and the hint you get depends on which one you are.
