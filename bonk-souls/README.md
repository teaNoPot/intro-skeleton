# Bonk Souls: Breath of the Mild

A tiny low-poly action game: Zelda: Breath of the Wild's climbing, gliding and stamina wheel, squeezed into a Dark Souls-shaped level instead of an open world. You are Pip, a turnip knight with a stale baguette. The Bloated King has hoarded all the soup.

## Play

Open `index.html` in a desktop browser (no build step; Three.js loads from a CDN). Click **Begin (and die)**.

| Key | Action |
| --- | --- |
| WASD | Move |
| Mouse / arrow keys | Look |
| Left click | Bonk (3-hit combo; roll, then click for a roll attack) |
| Right click | Heavy bonk (breaks poise) |
| Left click while falling | Plunge attack |
| Shift | Tap to roll (i-frames), hold to sprint |
| Space | Jump, press again in the air to glide, climb-jump while climbing |
| Q / middle click | Lock on |
| E | Interact (fires, messages, chests) |
| R | Slurp soup (heal, refills at fires) |
| C | Eat an apple (bonk apple trees to get them) |
| M | Mute |
| Esc / P | Pause |

## What's in it

- **Breath of the Wild bits**: climb any cliff (walk into it), a stamina wheel that empties while climbing, sprinting and gliding, a leaf glider, updraft vents, apple trees, chests, a hidden Nubbin who says "Yahaha".
- **Dark Souls bits**: stamina-based combat, dodge rolls with i-frames, lock-on, poise and staggers, Snoozefires (bonfires) that respawn enemies and let you level up, glimmers you drop on death and can go back for, fall damage, orange ground messages from "other turnips", a fog gate and a two-phase boss.
- **Enemies**: Blobkins (jellies with toothpicks), Shroomlugs (sleepy mushrooms with logs and delayed slams), Pebblers (nosy rock-throwing goblins), and Ser Belchalot, the Bloated King (a giant toad with a fork, a tongue, a belly flop and, when angry, fire burps).

Everything, including the sound, is generated in code. The level is hand-shaped from a height function: Cellar Hollow → Mildew Meadows (and Snack Mesa) → Mossy Nook → the Wobbly Bridge → Crumbling Keep → Throne of Bloat.
