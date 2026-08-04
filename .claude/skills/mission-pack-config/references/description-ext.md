# description.ext mission-maker checklist

Fields every mission maker should edit before shipping a mission:

```
author          = "YOURNAMEHERE";
onLoadName      = "Mission Pack v4.8.0";   // mission title
onLoadMission   = "YOURTEXTHERE";
maxPlayers      = 31;                       // set to your playercount
respawnDelay    = 20;                       // seconds
```

Replace `Pictures\loading.jpg` with a custom loading screen image if the
mission wants its own cover (the WMP dev repo generates this
programmatically from `onLoadName`'s version string — that generator itself
lives in `releaseVerificationAndDeployment/`, which is dev-only tooling and
won't be present in a mission maker's own project; for an end-user mission,
just drop in a replacement JPG).

## Never touch

`respawnOnStart` **must stay `-1`** — the loadout-saving system depends on
it. This is the single most important "don't touch this" in the whole pack;
flag it explicitly if a user's request would change it (e.g. "I want players
to spawn once and not respawn at all" needs a different mechanism, not this
field).

## Custom end screen

If configuring `Waldo_fnc_ENDEX`'s custom end path (see `endex-aar.md`),
`CfgDebriefing` → `End1` also lives in `description.ext`.
