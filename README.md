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
- **Collect** — 64 original characters, Common to Transcendent, with Golden / Diamond /
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
  Boulevard Legend (5), Ohio Royalty (10). Every rebirth also adds +5%
  permanent boss damage for the raids below.

## What's new in v3

- **Trading (T)** — offer one of your brainrots (plus optional cash) for one
  of another player's. Offers live 60 seconds in their inbox; an accepted
  offer needs BOTH sides to confirm before the server swaps anything, and
  the server re-validates ownership at confirm time. A 5% fee applies to
  the cash side (waived by the Trade Pass from the shop). A brainrot in a
  live offer cannot be stolen out from under the deal.
- **Boss raids** — once an hour the Mega Ohio Final Boss spawns on the raid
  pad south of the spawn (5,000 HP, 5 minutes). Press **F** near the pad to
  hit it, or slap it for double damage; pets add +5% damage each, rebirths
  +5% each, the Raid Potion +50% for 5 minutes. When the boss dies the
  $50,000 reward pool splits by damage share, and the top hitter wins a
  free Epic-or-better brainrot on their base. Boss Raid also joins the
  90-second event rotation.
- **Sky Plaza** — 12 plots now: 4 float 40 studs up in a new sky district,
  reached by the lift pad (or a Sky Key from the shop), earning +25%
  income. Pillars, railings, star lamps and a return pad complete it.
- **Coin rush minigame** — every 3 minutes a 45-second rush spawns up to 12
  gold coins around the fountain ring; click one for $250, and the top
  collector takes a $5,000 bonus. Your best rush shows on the board.
- **Teams (Y)** — found a team for $10,000 (max 5 members), share a vault
  that pays every member $500 an hour from deposits, and climb the team
  board by combined lifetime earnings. The leader's crown passes on when
  they leave; the last member out dissolves the team.
- **Cast** — 15 new characters, 37 → 52, including two new Transcendents:
  Supreme Ohio Overlord ($15,000/s) and Mega Ohio Final Boss ($18,000/s).
- **Shop** — three new items: Raid Potion ($3,000), Trade Pass ($2,500),
  Sky Key ($5,000). Every 10th conveyor spawn is a Sky Express that walks
  the belt twice as fast.

## What's new in v6

- **Daily login rewards (D)** — come back every day and the Daily Shrine
  east of the fountain pays out: a 7-day ladder from $2,500 on day 1 to a
  $60,000 jackpot on day 7, plus a $25,000 milestone chest on every 7th
  day in a row. Miss a day and the streak restarts at day 1. The panel
  shows the live streak, today's reward, and the countdown to tomorrow.
- **Shrine blessing** — claim while standing on the glowing Daily Shrine
  pad (two gold pillars, one neon beacon) and the shrine adds +25% on top
  of the day's cash. The server checks your position at claim time, so
  the bonus is earned, not asked for.
- **Cast** — 12 new characters, 52 → 64, across every rarity: Baron Butter,
  Captain Ketchup, Lady Latte, Duke Donut Hole, Professor Pancake, Madame
  Mustard, Sultan of Syrup, Queen Quiche, Doctor Dumpling, The Cereal
  Killer, Grand Emperor of Ohio ($24,000/s) and Shrine Keeper Sam, the
  Secret who watches your streak.
- **Server** — `DailyRewardService` (RemoteFunction claim + status, streak
  math, milestone chests, shrine blessing) wired into the bootstrap, with
  streak fields in `DataService` and a `daily` table on the HUD snapshot.
- **Tuning** — the whole ladder lives in `Config.DAILY_REWARD_LADDER`,
  with the milestone day, milestone bonus, shrine position, shrine radius
  and blessing rate beside it, so a balance pass is one edit.

## Layout

- `main.ts` (Node 22, stdlib only) hands the game in: it copies `game.rbxl`,
  `src/`, `screenshots/` and `PLAY.json` to `/output`, leaving out every name
  that starts with a dot, and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts` (the kit's copy, unchanged).
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`
  (`rojo build default.project.json --output game.rbxl`).
- `src/shared/` — `Config` (all tuning, the 6 pets, event weights, rebirth
  milestones, v3 trade / raid / minigame / team tuning, 12 plots with 4 in
  the Sky Plaza), `BrainrotData` (the 64-character cast,
  rarities, mutations), `Utils` (money formatting, weighted picks, clamps,
  duration / percent formatting).
- `src/server/` — one service per job: `DataService` (player state + income
  tick, pets + quests + trade / raid / minigame / team in the snapshot), `BrainrotFactory` (the 3D characters + slap tool + crown + pet models + boss model + gold coin),
  `WorldBuilder` (decor, pedestals, tsunami wave, pet park, quest board, Sky Plaza, raid pad, trading post, coin ring), `BaseService` (plots),
  `ConveyorService` (spawning, walking, buying, Sky Express lane), `StealService` (grab, carry,
  claim, slap, raid slap hook, trade-offer lock), `ShopService` (now with Raid Potion / Trade Pass / Sky Key), `EventService` (Golden Hour / Rain / Tsunami /
  Meteor Shower / Double Cash Hour / Slime Invasion / Boss Raid),
  `RebirthService` (pet bonus + milestones + raid damage bonus), `LeaderboardService` (top-5 earners + persistent bests + team bests),
  `PetsService` (buy/equip pets, income bonus, raid cheer bonus), `QuestService` (daily quests + v3 trade / raid / minigame counters),
  `TradeService` (offers, two-sided confirm, fee, expiry), `RaidService` (hourly boss, damage shares, reward pool),
  `MinigameService` (coin rushes, click-to-collect, best-score board), `TeamService` (teams, shared vault, hourly payout),
  and `init.server.luau` (bootstrap + remotes).
- `src/client/` — `Game.client.luau` (E to buy/steal/claim, Q for the shop,
  P for pets, J for quests, T for trading, Y for teams, F to hit the boss,
  sky lift teleport, pet follower rendering) and
  `Hud.luau` (top bar, prompt, shop, collection, rebirth, event banner,
  leaderboard panel, personal stats line, pets panel, quests panel, trade
  panel, raid bar, minigame panel, team panel).
- `screenshots/` — three frames of the game; the first is also the game's
  thumbnail on Roblox. Rendered headlessly from the place's own layout data
  (see `tools/render_screenshots.py`) because this build machine has no
  Roblox Studio; replace with real Studio captures after publishing.
- `TOUR.json` — the reviewer's tour: start screen, press E to buy, then the
  boss raid via `RaidService.spawnBoss("mega-ohio-boss")`.

## Publish status

`PLAY.json` still holds placeholder ids (`0` / `PENDING_PUBLISH`): the place
is built but not yet published on Roblox. Only the Roblox account owner can
publish it — the ordered steps are in `PUBLISH.md` (upload `game.rbxl`,
set Public, add the play code to the description, upload the icon and
`1-thumbnail.jpg` as the thumbnail, copy `place_id` + `universe_id` back
into `PLAY.json`).
