# Bonk Souls: Breath of the Mild

A tiny low-poly multiplayer game: Zelda: Breath of the Wild's climbing, gliding and stamina wheel, squeezed into a Dark Souls-shaped level, and you don't get to pick who you are.

## The idea

When you join, Mildhollow decides what you are. There are only two heroes, **Pip** (a turnip knight with a baguette) and **Radia** (a radish). Everyone else becomes something else:

| Monsters | Objects |
| --- | --- |
| Blobkin, Shroomlug, Pebbler, **Ser Belchalot** (the final boss, one at a time) | Cactus, Rock, Clay Pot, Apple Tree, Apple, The Wind, **Old Man Mountain** (one at a time) |

Monsters and objects fight the heroes with their own moves (a pot can explode, the wind blows heroes off cliffs or gives gliders a lift, the mountain throws boulders and sneezes, heroes can eat you if you're an apple). Die as a monster or object and you're reborn as something random. Hold **X** any time to leave and come back as something else.

## Shared, saved world

- Everyone viewing the page right now plays in the same world. The oldest tab runs the AI monsters, and everyone sees the same thing.
- The world is saved: lit Snoozefires, opened chests, found secrets and the boss's death. When the frog regrows (5 minutes after dying), chests refill for a new cycle.
- **Heroes are saved too.** Pip's and Radia's health, level, glimmers, soups, dropped glimmers and quest progress belong to the hero, not the player. Leave, and whoever becomes Pip next picks up exactly where you left off. If nobody is playing a hero, it naps where it was left.
- Old Gourd in Cellar Hollow gives the heroes a quest chain: kindle the fire, fetch apples, bonk Blobkins, find the Nubbin, climb the mountain, pop the frog.
- **Proximity chat:** press Enter to talk. Only players nearby see your message over your head, and it's read aloud in a silly voice for each character (V toggles voices). Real microphone voice chat isn't possible inside a Claude artifact, so this is text-to-speech.

Multiplayer and saving need the page to be opened as a published Claude artifact (it uses the artifact `room`, `db` and `user` capabilities). Opened as a plain file, it runs solo with the same random roles.

## Controls

| Key | Hero | Everyone else |
| --- | --- | --- |
| WASD, mouse (or arrows) | Move, look | Move, look |
| Left / right click | Bonk combo / heavy bonk | Your role's two moves (shown on screen) |
| Space | Jump, press again to glide | Your role's third move (usually hop) |
| Shift | Tap to roll, hold to sprint | Sink (the wind) |
| Q | Lock on | Lock on to a hero |
| E | Interact, talk to Old Gourd, eat apple-people | Read messages |
| R / C | Slurp soup / eat an apple | |
| Enter | Talk to people nearby | Talk to people nearby |
| Hold X | Become something else | Become something else |
| V / M / Esc | Voices / mute / pause | Voices / mute / pause |

Everything, including sound, is generated in code. Three.js loads from a CDN.
