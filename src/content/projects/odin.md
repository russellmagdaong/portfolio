---
title: ODIN
tagline: A tutoring system disguised as a dungeon crawler.
status: shipped
meta: Undergraduate thesis · defended 2026 · team of four
line: Thesis, defended 2026
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

ODIN is my undergraduate thesis, built with three teammates as InsomniCode, and we have defended it. It teaches C# arrays through a pixel-art RPG: you walk a dungeon, run into an enemy, and win the fight by writing real code in an in-game editor.

What happens after you hit submit is the interesting part. The game records how you typed (your pauses, your bursts, how much you changed between attempts) and sends that with your code to an ASP.NET Core backend. Roslyn reads the code to find the exact misconception, such as an off-by-one loop bound, and Bayesian Knowledge Tracing estimates how well you know each skill.

The typing data tells a student who is thinking apart from one who is guessing or stuck, and the hint you get depends on which one you are. I presented the paper at the FEU Tech Research Colloquium 2026.
