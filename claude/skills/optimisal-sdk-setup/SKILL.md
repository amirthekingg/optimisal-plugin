---
name: optimisal-sdk-setup
description: Add Optimisal's Roblox SDK to a game and check telemetry arrives. Use when someone wants to connect a Roblox game to Optimisal, install or start the SDK, set the ingest key, turn on client telemetry, or asks why no data shows up on the Optimisal dashboard.
---

# Set up the Optimisal SDK in a Roblox game

The SDK is a server ModuleScript named `Optimisal` (source in `sdk/roblox/src` of the Optimisal
repo; Rojo project `sdk/roblox/default.project.json`). The `optimisal://guide/sdk` MCP resource
has the full API; read it before writing code.

## Steps

1. **Find the game's layout.** Rojo (`default.project.json`), Script Sync, or plain Studio. Find the
   one server entry Script (usually in ServerScriptService). Don't add a second entry point if one
   exists: start the SDK from it.
2. **Add the module** to ServerScriptService as `Optimisal`. With Rojo, map `sdk/roblox/src` (or a
   copy) into `ServerScriptService.Optimisal`.
3. **The ingest key never goes in code or chat.** The owner creates it on Optimisal's Setup page
   (shown once) and stores it as a Roblox secret named `optimisal_ingest` for the experience
   (and as a local secret for Studio playtests). Tell the person to do that; never ask them to
   paste the key to you, and never write it into a file.
4. **There's no player salt to set.** Optimisal makes a key for each game and sends it to the
   game's servers with the config edge; the SDK hashes players with it (`h1_…`). Don't add a salt.
5. **Start it once**, as early as possible in the server entry:

   ```lua
   local HttpService = game:GetService("HttpService")
   local Optimisal = require(game:GetService("ServerScriptService").Optimisal)

   -- GetSecret errors when the secret isn't set, so the game keeps running without it.
   local hasKey, ingestKey = pcall(HttpService.GetSecret, HttpService, "optimisal_ingest")
   if hasKey then
   	Optimisal.start({
   		ingestKey = ingestKey,
   		endpoint = "https://YOUR-HOST/v1/ingest",
   	})
   else
   	warn("[Optimisal] no optimisal_ingest secret; telemetry is off")
   end
   ```

   Ask the person for their Optimisal address (it's the address of their dashboard).
6. **Game settings:** Allow HTTP Requests must be on, and the place must be published (the SDK is
   off when PlaceId is 0).
7. **Client telemetry** (FPS, ping, client errors, feedback, public LiveOps values and
   announcements) is on by default: `start()` puts `OptimisalClient` in ReplicatedStorage. The
   client entry calls `require(ReplicatedStorage:WaitForChild("OptimisalClient")).start()`. Pass
   `clientTelemetry = false` to turn it off.
8. **Check it arrives.** After a playtest in a published place (or a live server), use the MCP
   tools: `list_games` for the game ID, then `game_overview` should show servers and players
   within a minute, and `top_errors` any errors. If nothing shows: Output will have an
   `[Optimisal]` warning (no key, not published, HTTP off); `start({ debug = true })` shows more.

## Rules

- The SDK never throws or yields the game, so calls need no `pcall`. Don't wrap it in retries.
- Raw user IDs never leave the server; the SDK hashes them with the game's key. Never send a user ID,
  username or display name in `track()` props.
- Don't change the live game from here: changes go through the person's normal publish.
