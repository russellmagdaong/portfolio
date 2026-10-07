---
title: TAKO
tagline: A math RPG that works without internet.
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

TAKO is an Android game for Grades 7 to 10, aligned with the DepEd curriculum and playable in English or Filipino. It was built for students who don't have reliable internet, so everything runs from a local SQLite database and syncs to Supabase only when a connection exists.

Gemini writes the questions and the feedback, but it never grades anything. Answers are checked by ordinary code that knows `1/2`, `0.5` and `2/4` are the same number, and wrong answers are matched to known mistakes before the AI is asked to explain them. If the AI is unreachable, the game falls back to templates and keeps going.
