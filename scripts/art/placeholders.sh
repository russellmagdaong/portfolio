#!/usr/bin/env bash
# Makes the grey placeholder art for phase 3: the map, its buildings, and the six
# scenes with their things along the wall. It never draws over a file that
# exists, so delete the placeholders you want made again first. Then run
# `npm run art`.
#
#   bash scripts/art/placeholders.sh
#
# Each scene's things are kind:id:WxH:... (see scripts/art/new-scene.lua). The ids
# match the page: show:<id> shows the page's <Show id>, prop:<id>:...:<tip> the
# page's <Tip id>, object:<id>:...:<opens> opens the page's <Panel id>.

set -e
ASE="${ASEPRITE:-C:/aseprite/build/bin/aseprite.exe}"
cd "$(dirname "$0")/../.."
mkdir -p art/scenes art/map-objects

if [ -e art/map.aseprite ]; then
  echo "kept art/map.aseprite and art/map-objects/ (the map already exists)"
else
  "$ASE" -b --script scripts/art/new-map.lua
fi

scene() {
  if [ -e "art/scenes/$1.aseprite" ]; then echo "kept art/scenes/$1.aseprite (it already exists)"; return; fi
  "$ASE" -b --script-param name="$1" --script-param width="$2" --script-param placeholder=1 \
    --script-param "things=$3" --script-param "exit=${4:-left}" --script scripts/art/new-scene.lua
}

# Home starts at the corkboard with the controls, and its door out is at the far end.
scene home 480 "show:corkboard:96x64:paper,object:mirror:30x44:mirror:De-pixelate,show:poster:96x64:paper,show:pc:84x56:screen,prop:guitar:14x36:music,prop:console:24x16:games,prop:camera:16x26:video,prop:flag:14x40:ctf,prop:trophy:14x20:hackathons" right
scene school 480 "show:about:200x104:paper,show:profile:132x104:paper"
scene arcade 640 "object:odin:30x40:odin:Play,object:tako:30x40:tako:Play,object:algebrawl:30x40:algebrawl:Play,object:runner:30x40:runner:Play"
scene store 480 "show:tools-games:64x48:shelf,show:tools-web:100x56:shelf,show:tools-backend-and-data:116x56:shelf,show:tools-also-comfortable-in:84x48:shelf"
scene trophy-shop 480 "show:achievements:124x96:paper,show:certs-certifications:96x64:paper,show:certs-ctfs:150x84:paper,show:certs-hackathons:116x70:paper,show:certs-academic:64x60:paper"
scene post-office 480 "show:socials:84x40:paper,object:counter:48x30:contact:Write"
