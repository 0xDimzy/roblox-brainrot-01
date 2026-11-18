# Publish handoff — Brainrot Boulevard (roblox-brainrot-01)

The game is built and ready. Only the Roblox account owner can publish it —
no password or login is ever needed from the agent. Do these steps in order
on a Windows or Mac computer with Roblox Studio installed and signed in.

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

1. **Icon** — upload a square picture, 512×512 is best. (Make one from
   `screenshots/1-thumbnail.jpg`, cropped square — any image editor works.)
2. **Thumbnails** — on the Experience Detail Page tab, upload
   `screenshots/1-thumbnail.jpg` as the FIRST thumbnail.
3. Wait until the experience's page on Roblox shows both — Roblox reviews
   each upload, and the entry is refused while either is still in review or
   missing. The first thumbnail must be the same picture as one of the
   entry's screenshots: that is `1-thumbnail.jpg`.

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
the files, and keep `1-thumbnail.jpg` as the first thumbnail uploaded in
step 5.
