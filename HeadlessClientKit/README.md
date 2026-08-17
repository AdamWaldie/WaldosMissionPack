# WMP Headless Client Kit

This kit covers the half of headless-client (HC) setup that lives **outside the mission** —
connecting an actual headless-client process to your server. It is a separate download from the
main WMP pack because it is server-hosting tooling, not mission content: nothing here is loaded by
a mission, and none of it ships inside `WMP-<version>.zip`.

For the in-mission half — turning `Waldo_Headless_Enable` on, placing Headless Client slots in
Eden, and how WMP actually distributes AI groups once a headless client is connected — see
[`wiki/Headless-Client-Support.md`](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Headless-Client-Support)
in the main pack's wiki. Do the mission-side setup there first; this kit is only useful once you
have a mission with `Waldo_Headless_Enable` set to `true` and at least one Headless Client slot
placed and set Playable.

## What's in here

| File | Purpose |
|---|---|
| `server.cfg.snippet.example` | The exact `server.cfg` keys a headless client needs allow-listed, annotated. Copy the two array entries into your **existing** `server.cfg` — this is a snippet to merge in, not a full server.cfg to replace yours with. |
| `launch_headless_client.ps1` | Launches one headless-client process against a server you already have running (local or remote). Parameterized for server IP, port, password, mods and profile name. |
| `launch_local_dedicated_with_headless.ps1` | Spins up a local dedicated server plus N headless clients on your own machine in one go, so you can rehearse the whole HC setup before pointing it at a real host. Windows/PowerShell, mirrors the pattern the pack's own QA launchers already use. |
| `headlessConfig.examples.sqf` | A few named example parameter sets beyond the single default WMP ships in `MissionConfig\headlessConfig.sqf` — conservative (slow, cautious pacing for a first HC test) and aggressive (fast migration for a large, established AI population). Copy the block you want; don't `#include` this file directly. |

## What Arma 3 itself actually requires

This is the complete list of what the *engine* requires for a headless client to work at all,
independent of WMP - confirmed against Bohemia's own headless-client documentation and current
hosting-provider guidance. Everything in this kit exists to satisfy these points correctly:

1. **`server.cfg` must allow-list the connecting IP** in `headlessClients[]`. A connection from an
   IP not listed there is refused the headless role outright - the server does not accept arbitrary
   headless connections. Also list same-machine HCs in `localClient[]` so the server does not budget
   network bandwidth for a connection that never leaves the machine.
2. **The HC process authenticates with the server's own join password** via `-password=`. There is
   no separate "headless client password" - it is the same `password` key already in your
   `server.cfg`.
3. **Launch with `-client -connect=<serverIP>`** (plus `-port=`, `-name=`, `-profiles=` and
   `-mod=` as needed). There is no separate headless-client executable - `arma3_x64.exe` becomes
   headless purely because of the `-client` flag; running the *server* executable here starts a
   second dedicated server instead, not a headless client.
4. **The headless client's modset must match the server's**, exactly like any normal connecting
   client - a missing or mismatched mod fails the connection the same way it would for a player.
5. **Headless clients count toward `description.ext`'s `maxPlayers`.** Undersizing `maxPlayers` for
   your human player count plus HC count silently prevents an HC from ever being assigned a slot,
   even though the network connection itself succeeds.
6. **The mission needs a Playable Headless Client slot to connect into** (Eden's Systems/Logic
   entity category, `forceHeadlessClient` set) - a connecting, allow-listed HC auto-fills the first
   free one. This part lives in the mission itself, covered by
   [`wiki/Headless-Client-Support.md`](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Headless-Client-Support),
   not this kit.
7. **A headless client renders nothing**, so `-limitFPS=<n>` is a widely recommended addition (both
   launch scripts here default to it) to stop it burning a full CPU core at an uncapped framerate
   for no visible benefit.
8. **The engine only gets a connected headless client into the mission slot; it does not, by
   itself, move any AI onto it.** Whether AI actually ends up owned by the HC is entirely up to the
   mission's own scripting - WMP's native system (`Waldo_Headless_Enable`, again see the wiki page
   above) is what does that for a WMP mission.

## Quick setup

1. Confirm the mission side is done first: `Waldo_Headless_Enable` is `true` in
   `MissionConfig\headlessConfig.sqf`, and you have run the manual HC test matrix in the wiki page
   above for your mission's mod set.
2. Open `server.cfg.snippet.example`, and merge its `headlessClients[]` (and `localClient[]`, if
   applicable) entries into your real `server.cfg`, replacing the placeholder IP with your actual
   headless-client machine's IP.
3. Restart (or start) your dedicated server so it picks up the updated `server.cfg`.
4. Edit the parameters at the top of `launch_headless_client.ps1` (server IP, port, password, mod
   list, Arma install path) and run it. A headless client has no window — if it connected
   successfully you will see it join in your server's RPT log and, shortly after, in WMP's own
   `[WMP DIAG]` headless-client diagnostics row.
5. Never tested this locally before? Run `launch_local_dedicated_with_headless.ps1` first — it
   stands up a throwaway dedicated server and one or more headless clients on your own machine, so
   you can see the whole connection flow work before doing it against a real host.

## What this kit deliberately does not do

- It does not install or configure Arma 3, BattlEye, or your hosting provider's control panel —
  every host's setup differs; this kit only covers the parts that are the same everywhere
  (`server.cfg` keys and Arma's own `-client` launch parameters).
- It does not touch mission files. `Waldo_Headless_Enable`, the Headless Client Eden slots, and
  every in-mission HC behaviour live in the main WMP pack and its wiki, not here.
- It does not manage the headless-client process for you (auto-restart, monitoring, service
  wrapping). These are plain example launch scripts, not a service manager.

## Why this ships separately

Actually running a headless-client process is server administration, not mission scripting — a
different skill and a different audience than the rest of WMP. Keeping it out of the main pack
means a mission maker who never runs a headless client never has to see it, while a server admin
who wants it can grab exactly this kit without the rest of the pack. See `CLAUDE.md`'s Build &
Release section in the main repository for how this kit is packaged and released.
