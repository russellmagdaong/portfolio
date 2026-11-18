---
title: NOVA
tagline: A "Hey Nova" voice assistant for Windows that answers with Claude.
status: building
meta: Personal project · started November 2026
line: Voice assistant, Windows
gallery:
  - src: ../../assets/projects/nova/logo.png
    alt: The NOVA logo, a planet with an orbit swinging around it, and the words "Not Only a Voice Assistant"
  - src: ../../assets/projects/nova/notch-speaking.png
    alt: NOVA's notch at the bottom of the screen, a pixel-art black cat under a card with NOVA's spoken answer about tomorrow's weather
  - src: ../../assets/projects/nova/notch-listening.png
    alt: The notch while you talk, showing your question as a live caption
  - src: ../../assets/projects/nova/mascots.png
    alt: NOVA's six pixel-art mascots (a cat, a robot, a fox, a frog, a ghost and an axolotl) in every state, from idle and talking to asleep and sad
stack: [Python, PySide6, Claude Code CLI, faster-whisper, Vosk, Kokoro TTS]
source: https://github.com/russellmagdaong/nova-voice-assistant
order: 0
---

Say "Hey Nova" and ask anything. NOVA answers out loud, using Claude through the signed-in Claude Code CLI, so it needs no API key. It lives at the bottom of the screen as a pixel-art mascot that peeks up from the edge, blinks while it waits, and pops up with a card when you talk to it.

The wake word runs offline with Vosk, Whisper turns what you said into text, and Kokoro speaks the answer on the GPU in under a second. You can talk over it to interrupt, and keep the conversation going without saying the wake word again. It looks things up when it has to (weather, news, the web) and can run timers, reminders, notes, the volume and Spotify.

The part I spent the most time on is what it can't do. Claude gets a short list of tools and nothing else: no shell, no files and no settings. Every input is checked, and apps only open if you ticked them yourself.
