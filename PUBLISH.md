# Publish handoff — Brainrot Boulevard (roblox-brainrot-01)

The game is built and ready. Only the Roblox account owner can publish it —
no password or login is ever needed from the agent. Do these steps in order
on a Windows or Mac computer with Roblox Studio installed and signed in.

## v3 changelog (branch v4)

- **Trading (T)** — new `TradeService`: player-to-player offers (your
  brainrot + optional cash for theirs), 60-second expiry, two-sided
  confirm, server re-validates ownership at confirm time, 5% cash fee
  (Trade Pass waives it). Inbox panel in the HUD; a brainrot in a live
  offer cannot be stolen.
- **Boss raids** — new `RaidService`: hourly boss (Mega Ohio Final Boss,
  5,000 HP, 5 minutes) on a new raid pad; F to hit, slaps deal double;
  pets / rebirths / Raid Potion boost damage; $50,000 pool splits by
  damage share, top hitter wins a free Epic-or-better brainrot. Boss
  Raid also joins the event rotation.
- **Sky Plaza** — 12 plots (4 floating at y=40, +25% income), lift pad
  and return pad, pillars, railings, star lamps; `BaseService.isOnPlot`
  now checks Y so ground and sky plots never confuse each other.
- **Coin rush minigame** — new `MinigameService`: every 3 minutes, 45
  seconds, up to 12 clickable gold coins around the fountain ring
  ($250 each, $5,000 top-collector bonus, best-score board).
- **Teams (Y)** — new `TeamService`: create for $10,000, max 5 members,
  shared vault paying $500/member/hour from deposits, team board by
  combined earnings, leader succession, dissolve on last leave.
- **Cast** — 15 new characters, 37 → 52, including two Transcendents
  (Supreme Ohio Overlord $15,000/s, Mega Ohio Final Boss $18,000/s).
- **Shop** — Raid Potion, Trade Pass, Sky Key; every 10th conveyor
  spawn is a twice-as-fast Sky Express.
- Screenshots were re-rendered fresh from the v3 build; `PLAY.json` now
  carries `"version": 3` (place/universe ids still 0 — publish pending).

## v2.5 changelog (branch v3)

- **Pets (P)** — six purchasable companions (Milo the Moth to Void Kitten,
  $2,500–$100,000 in-game cash, +10% to +50% income each). The equipped pet
  follows the player; pets survive a rebirth and each one owned at rebirth
  time adds +5% permanent income. A pet park sits in the east corner.
- **Daily quests (J)** — three rotating quests a day (earn, buy, steal) with
  cash rewards and a clean-sweep bonus; progress is tracked server-side and
  a quest board stands west of the spawn pad.
- **Events** — three new ones join Golden Hour, Brainrot Rain and Tsunami:
  Meteor Shower (free brainrots crash onto random bases), Double Cash Hour
  (2x income), Slime Invasion (pop slimes for +$750 each).
- **Cast** — 10 new characters, 27 → 37, including The Algorithm
  (Transcendent, $12,000/s).
- **Rebirth milestones** — Boulevard Regular (3), Legend (5), Ohio Royalty
  (10), each paying a cash bonus on the rebirth that reaches it.
- Screenshots were re-rendered fresh from the v2.5 build; `PLAY.json` now
  carries `"version": 2` (place/universe ids still 0 — publish pending).

## 0. Before you start

- Your Roblox account must be at least 2 days old, in good standing, and past
  Roblox's age check (facial age estimation or government ID) if it asks.
- The play code for this entry (put it in the experience description, step 4):
  `makefun-petunia-pier-loom`

## 1. Open the place in Studio

1. Open Roblox Studio.
2. File → Open from File → pick `game.rbxl` from this repository.
3. Press Play once to check it runs: your character spawns on the blue pad,
   brainrots walk the conveyor, E buys one, Q opens the shop.

## 2. Publish it as a new experience

1. File → Publish to Roblox → Create New Experience.
2. Name it **Brainrot Boulevard**. (Genre: pick one Roblox offers.)
3. Publish. Note the experience it creates.

## 3. Make it Public

On the Creator Dashboard (https://create.roblox.com/dashboard/creations):

1. Open the Brainrot Boulevard experience → Configure.
2. Add a description and a genre, then answer Roblox's content questions
   (for a simple game: answer No to the age-restricted-content question).
3. Set Audience / Playability to **Public** and save.
4. If Roblox refuses Public, finish whatever it asks first (description,
   genre, content questions, age check) and try again.

## 4. Put the play code in the description

In the same Configure → Basic Info, add this line to the description
(exactly as written, on its own line):

```
makefun-petunia-pier-loom
```

Save. (Roblox refuses a description that reads as a web address — the code
above has no dot in it, so it saves fine.)

## 5. Upload the icon and the thumbnail

On the Creator Dashboard, open the experience → Configurations → Places →
choose its start place (marked with a star):

1. **Icon** — upload `publish-assets/icon-512.png` (512×512 square).
2. **Thumbnails** — on the Experience Detail Page tab, upload
   `publish-assets/thumbnail-bossraid.jpg` as a thumbnail. The FIRST
   thumbnail uploaded on Roblox was the keyart image,
   `screenshots/0-thumbnail-keyart.jpg` — not `1-thumbnail.jpg`.
3. Wait until the experience's page on Roblox shows both — Roblox reviews
   each upload, and the entry is refused while either is still in review or
   missing. The first thumbnail must be the same picture as one of the
   entry's screenshots: that is `0-thumbnail-keyart.jpg`.

## 6. Copy the ids back into PLAY.json

- `place_id` — the number in the play link:
  `https://www.roblox.com/games/<place_id>/Brainrot-Boulevard`
  (also `game.PlaceId` in Studio).
- `universe_id` — the number after `experiences/` in the experience's
  address on the Creator Dashboard (also `game.GameId` in Studio).

Edit `PLAY.json` in the repository to:

```json
{"url": "https://www.roblox.com/games/<place_id>", "place_id": <place_id>, "universe_id": <universe_id>}
```

Commit that change, then tell the agent: the entry can be submitted.
The agent will re-run the kit check (its `play_link` row must pass) and
submit with the same recording plus the publish recording.

## 7. (Optional) Replace the screenshots with real Studio captures

`screenshots/` currently holds headless renders of the place's own layout
(Roblox Studio has no Linux build, so this build machine could not capture
them). In Studio, with the game running, capture the same three screens —
start, play, tsunami event — at 1280×720, each under 256 KiB, and replace
the three files. Do this inside a new recording so the transcripts witness
the files, and keep `0-thumbnail-keyart.jpg` as the first thumbnail uploaded in
step 5.
