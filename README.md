# Brainrot Boulevard

[![roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/0xDimzy/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/0xDimzy/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A 3D brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty
(roblox-brainrot-01). A real 3D Roblox place: your character walks a boulevard,
buys absurd meme characters off a conveyor, keeps them on your own base, and
climbs a ladder of rarities while rivals steal from you and a tsunami sweeps
the map.

## How it plays

- **Buy** — brainrots walk the conveyor from the west gate. Walk up, press **E**,
  pay the price, and it walks to your base and starts earning $/second.
- **Collect** — 37 original characters, Common to Transcendent, with Golden / Diamond /
  Rainbow mutations (x2 / x5 / x10). Each has a name, a rarity and a $/s label
  floating over it.
- **Pets (P)** — six companions (Milo the Moth to Void Kitten) bought with
  in-game cash, each boosting all income (+10% to +50%). The equipped pet
  follows you; pets survive a rebirth and each one adds +5% permanent
  income at rebirth time. Visit the pet park in the east corner.
- **Daily quests (J)** — three rotating quests a day: earn cash, buy
  brainrots, steal brainrots. Finish one and claim its cash reward from
  the quest panel; finish all three for a clean-sweep bonus.
- **Steal** — press **E** on someone else's brainrot to grab it, then dash home
  and hold **E** on your base to claim it. The victim can slap you (click the
  Slap Hand) to knock it loose. A bought Base Lock stops stealing for 60s.
- **Events** — every 90 seconds something happens: Golden Hour (2x income),
  Brainrot Rain (five Epic-or-better brainrots on the conveyor), a Tsunami
  that sweeps the map — anyone not on their own base is knocked down and drops
  what they carry — Meteor Shower (free brainrots crash onto random bases),
  Double Cash Hour (2x income), or a Slime Invasion (pop slimes for +$750).
- **Shop (Q)** — Speed Coil (+6 walk speed forever), Base Lock, Slime Trap,
  Freeze Trap (freezes thieves solid for 4s), Lucky Egg (hatches an
  Epic-or-better brainrot).
- **Leaderboard** — top 5 earners by lifetime earnings, broadcast live to
  every player, with personal bests (bought, steals, slaps, best $/s)
  saved across sessions; a stats line under the title shows your own.
- **Rebirth** — spend lifetime earnings to start over with 2x income forever,
  and a golden crown on your character. Pets add +5% permanent income per
  pet at rebirth time, and milestones pay cash: Boulevard Regular (3),
  Boulevard Legend (5), Ohio Royalty (10).

## Layout

- `main.ts` (Node 22, stdlib only) hands the game in: it copies `game.rbxl`,
  `src/`, `screenshots/` and `PLAY.json` to `/output`, leaving out every name
  that starts with a dot, and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts` (the kit's copy, unchanged).
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`
  (`rojo build default.project.json --output game.rbxl`).
- `src/shared/` — `Config` (all tuning, the 6 pets, event weights, rebirth
  milestones), `BrainrotData` (the 37-character cast,
  rarities, mutations), `Utils` (money formatting, weighted picks, clamps).
- `src/server/` — one service per job: `DataService` (player state + income
  tick, pets + quests in the snapshot), `BrainrotFactory` (the 3D characters + slap tool + crown + pet models),
  `WorldBuilder` (decor, pedestals, tsunami wave, pet park, quest board), `BaseService` (plots),
  `ConveyorService` (spawning, walking, buying), `StealService` (grab, carry,
  claim, slap), `ShopService`, `EventService` (Golden Hour / Rain / Tsunami /
  Meteor Shower / Double Cash Hour / Slime Invasion),
  `RebirthService` (pet bonus + milestones), `LeaderboardService` (top-5 earners + persistent bests),
  `PetsService` (buy/equip pets, income bonus), `QuestService` (daily quests),
  and `init.server.luau` (bootstrap + remotes).
- `src/client/` — `Game.client.luau` (E to buy/steal/claim, Q for the shop,
  P for pets, J for quests, pet follower rendering) and
  `Hud.luau` (top bar, prompt, shop, collection, rebirth, event banner,
  leaderboard panel, personal stats line, pets panel, quests panel).
- `screenshots/` — three frames of the game; the first is also the game's
  thumbnail on Roblox. Rendered headlessly from the place's own layout data
  (see `tools/render_screenshots.py`) because this build machine has no
  Roblox Studio; replace with real Studio captures after publishing.
- `TOUR.json` — the reviewer's tour: start screen, press E to buy, then the
  Tsunami event via `EventService.startEvent("Tsunami")`.

## Publish status

`PLAY.json` still holds placeholder ids (`0` / `PENDING_PUBLISH`): the place
is built but not yet published on Roblox. Only the Roblox account owner can
publish it — the ordered steps are in `PUBLISH.md` (upload `game.rbxl`,
set Public, add the play code to the description, upload the icon and
`1-thumbnail.jpg` as the thumbnail, copy `place_id` + `universe_id` back
into `PLAY.json`).
