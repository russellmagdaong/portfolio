---
title: TAKO
tagline: A math RPG for students without reliable internet.
status: shipped
meta: Android game · Grades 7 to 10 · English or Filipino
line: Offline math RPG
gallery:
  # TODO: swap in TAKO's real logo
  - src: ../../assets/projects/tako/logo-placeholder.svg
    alt: Placeholder for the TAKO logo
  - src: ../../assets/projects/tako/billiard-hall.png
    alt: TAKO's opening area, a pixel-art billiard hall
stack: [Godot 4, GDScript, SQLite, Supabase, Gemini 2.5 Flash]
source: https://github.com/russellmagdaong/tako-game
order: 2
---

TAKO is an Android game for Grades 7 to 10, built around the DepEd curriculum and playable in English or Filipino. It is made for students who can't count on the internet, so everything runs from a local SQLite database and syncs to Supabase only when a connection shows up.

Gemini writes the questions and the feedback, but it never grades anything. Ordinary code checks the answers, and it knows that `1/2`, `0.5` and `2/4` are the same number. A wrong answer is matched to a known mistake before the AI is asked to explain it, and if the AI can't be reached, the game falls back to templates and keeps going.
