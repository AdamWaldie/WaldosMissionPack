# Dialogue and Conversations

> **Use this page when:** an NPC should speak one or more timed lines, use reusable ambient
> archetypes, or run a choice-driven conversation that can advance mission objectives.

WMP deliberately ships two separate components. **Simple Dialogue** is the normal starting point:
one line in an NPC's Eden init field gives that NPC a Talk interaction. **Advanced Conversations**
is an optional power-user layer for named nodes, multiple speakers, recorded audio and player
choices. You do not need to understand Advanced Conversations to use Simple Dialogue.

## Which one should I use?

| You want... | Use... | First thing to do |
|---|---|---|
| An NPC to say one or several lines | Simple Dialogue | Put one `Waldo_fnc_SimpleDialogue` call in that NPC's Eden Init field. |
| Reusable ambient civilian chatter | Simple Dialogue archetype | Assign `CIVILIAN`, `CIVILIAN_FRIENDLY`, `CIVILIAN_WARY`, or one of the opt-in packs. |
| A task update after the NPC finishes | Simple Dialogue callback | Add the server completion-code argument shown below. |
| Questions, answers, branches or recorded voices | Advanced Conversation | Define the conversation once, then assign its ID to an NPC. |
| Zeus to apply or start dialogue during play | WMP Mission Flow ZEN modules | Place the relevant Dialogue/Conversation module on the NPC. |

For a first test, place a civilian and a playable unit about two metres apart, paste the following
into the civilian's **Init** field, and preview the mission:

```sqf
[this, "Hello. If you can read this, dialogue is working."] call Waldo_fnc_SimpleDialogue;
```

Walk up to the civilian and use **Talk**. That is the complete minimum setup.

## Simple Dialogue: start here

Put one of these directly in the NPC's Eden **Init** field. Do not add anything to `init.sqf` or
`initServer.sqf`; the component starts itself and the public function keeps server authority.

Random neutral civilian chatter:

```sqf
[this, "CIVILIAN"] call Waldo_fnc_SimpleDialogue;
```

One specific line:

```sqf
[this, "The clinic is at the end of the road."] call Waldo_fnc_SimpleDialogue;
```

Several lines in order:

```sqf
[this, [
    "Welcome to the village.",
    "You look like you have travelled a long way.",
    "The inn is beside the old bridge."
]] call Waldo_fnc_SimpleDialogue;
```

The Talk control is an ACE object interaction when ACE Interact is available and a vanilla hold action
otherwise. WMP calculates each line from its word count and punctuation, displays it to players who
are nearby when that line begins, and prevents two players from talking to the same NPC at once.

### Complete an objective after the NPC finishes

The compact callback form is `[target, lines, completion code, remove after use]`:

```sqf
[this, [
    "I saw the vehicle heading north.",
    "Try the old service road."
], {
    params ["_speaker", "_caller", "_context"];
    ["obj_find_vehicle", "Succeeded"] call BIS_fnc_taskSetState;
}, true] call Waldo_fnc_SimpleDialogue;
```

The code is retained and executed by the server only. It runs exactly once after every line
completes; walking away, dying or losing the NPC cancels the session without completing the task.
The final `true` removes the dialogue after successful use. Omit it or use `false` for repeatable
dialogue.

The original five-position form is also supported:

```sqf
[this, "SPECIFIC", ["First line.", "Second line."], { /* completion code */ }, true]
    call Waldo_fnc_SimpleDialogue;
```

Apply one archetype to every unit in a group from any member's init field:

```sqf
[group this, "CIVILIAN_WARY"] call Waldo_fnc_SimpleDialogue;
```

Remove Simple Dialogue later:

```sqf
[this] call Waldo_fnc_SimpleDialogueClear;
```

## Included archetypes and example packs

The always-available neutral IDs are `CIVILIAN`, `CIVILIAN_FRIENDLY` and `CIVILIAN_WARY`.

Two larger catalogues are opt-in so their prose never appears in an unrelated mission. Simply use
one of their IDs and WMP loads that example pack on demand:

```sqf
[this, "MODERN_CIVILIAN"] call Waldo_fnc_SimpleDialogue;
```

Modern IDs are `MODERN_CIVILIAN`, `MODERN_CIVILIAN_FRIENDLY`, `MODERN_CIVILIAN_WARY`,
`MODERN_CIVILIAN_DISPLACED`, `MODERN_SHOPKEEPER`, `MODERN_RURAL_RESIDENT`, `MODERN_AID_WORKER`
and `MODERN_LOCAL_OFFICIAL`.

The medieval example is selected the same way; its IDs are `DORNOW_CIVILIAN`,
`DORNOW_GUARD`, `DORNOW_SHOPKEEPER` and `DORNOW_FARMER`.

`Waldo_fnc_DialogueLoadPresetPack` remains available when a script author deliberately wants to
preload `MODERN_CIVILIANS` or `MEDIEVAL_DORNOW`, but beginners do not need that extra step.

## Advanced Conversations

Advanced Conversations are defined once, then assigned to NPCs. The beginner builder uses readable
rows rather than requiring HashMaps. Each node is:

```text
[node ID, lines, choices, on-enter code, automatic next node]
```

Each choice is `[label, next node, condition, on-select code, optional choice ID]`. Empty next-node
text ends the conversation.

```sqf
["CHECKPOINT", [
    ["START", [
        "Good morning. What do you need?"
    ], [
        ["Is this road open?", "ROAD"],
        ["Nothing. Goodbye.", ""]
    ]],
    ["ROAD", [
        "The main road is blocked.",
        "Use the service track behind the depot."
    ], []]
], "START", {
    params ["_speaker", "_caller", "_context"];
    ["obj_find_route", "Succeeded"] call BIS_fnc_taskSetState;
}] call Waldo_fnc_ConversationCreate;

[this, "CHECKPOINT"] call Waldo_fnc_ConversationAssign;
```

The player who starts the conversation sees a modal response panel with clickable choices and a
visible cancel button. While that panel is open, Arma routes input to the display rather than to
gameplay, so number keys cannot change weapons and no custom gameplay binding is intercepted.
Nearby players see each spoken line but cannot choose for the initiator. Closing the panel cancels.
The client also closes the panel itself if the speaker/caller is killed, deleted, incapacitated,
respawned, moved beyond cancellation range, loses the active session, or the display is otherwise
lost. This fail-open path does not wait for a server cleanup message before returning player control.

### Response-panel sizing

The panel is content-aware. Short choices produce a compact panel rather than a full-width box.
Long labels wrap and make their own rows taller. Up to eight choices are supported in one node; if
their combined height reaches the configured cap, the response list scrolls while its title and
cancel path remain available. The shipped automated in-engine test exercises eight deliberately long
responses and rejects clipped rows, an oversized panel, or a list that fails to become scrollable.

There are deliberately no `1`-`8` shortcuts. Responses are clicked, and the modal display prevents
weapon-selection or other gameplay bindings from firing underneath it. Closing the display, clicking
**Cancel conversation**, moving away, dying, respawning, or losing either unit returns control.

### Multiple speakers and recorded audio

A plain line string uses the assigned NPC. An enriched line is:

```sqf
[speakerObject, "Subtitle text", "CfgSoundsId", soundDuration, textDurationOverride, "GestureName"]
```

Use `objNull` as the speaker to keep using the assigned NPC. Audio is optional. `soundDuration`
controls subtitle/session timing for a recorded line; otherwise WMP uses the text estimator.
Missing `CfgSounds` entries are logged and the subtitle continues without audio.

WMP enables the speaker's facial mimics and uses local lip animation while each line is active, even
when there is no recorded sound. The AI owner receives one `lookAt` order at conversation start and
the target is cleared at the end. WMP does not repeatedly force the civilian's direction, which avoids
the visible left/right rotation jitter that a per-frame turning loop causes. If a headless client owns
the civilian, those AI-local commands run there instead of being incorrectly forced on the server.

Power users may call `Waldo_fnc_ConversationRegister` with the documented HashMap schema used by
the builder, then use `Waldo_fnc_ConversationAssign`, `Waldo_fnc_ConversationStart`,
`Waldo_fnc_ConversationCancel` and `Waldo_fnc_ConversationClear` directly. Conditions and hooks
receive `[_speaker, _caller, _context]` and remain on the server.

## Zeus Enhanced

The **WMP Mission Flow** category contains:

- **Dialogue - Apply Simple Archetype**
- **Dialogue - Assign Simple Lines** (separate lines with `|`)
- **Dialogue - Clear**
- **Conversation: Assign**

Place assignment modules directly on the NPC; they can optionally apply to the NPC's entire group.
Advanced conversations are authored in mission scripts with `Waldo_fnc_ConversationCreate` or
`Waldo_fnc_ConversationRegister`, then assigned in Zeus by selecting their public conversation ID.
Private conditions and hooks remain server-side and are never replicated to curators.

## Timing, multiplayer and limits

Defaults live in `MissionConfig\dialogueConfig.sqf`: 0.5 seconds per word, 1.5-15 seconds per
line, punctuation pauses, a 10 m audience, 3 m interaction distance and 6 m cancellation distance.
Simple Dialogue permits 32 lines of 500 characters. Advanced Conversations permit 128 nodes,
16 lines and eight choices per node, and 256 transitions in one session.

The same config exposes safe-zone-relative minimum/maximum widths, height caps and text scales for
subtitles and response choices. Subtitle height follows wrapped text. Choice rows grow for wrapped
labels; the response region scrolls when the complete set cannot fit its configured height cap.
Both panels call the shared WMP theme resolver, so era fonts/colours and the player's local
colour-vision accessibility overrides are applied together.

### Editing the dialogue config safely

1. Open `MissionConfig\dialogueConfig.sqf` in the mission pack.
2. Change only the value on the right-hand side of the setting you need.
3. Keep widths/heights as safe-zone fractions (`0.34` means 34% of the usable screen area), not
   pixel counts.
4. Restart or rebuild the mission. These are guarded startup defaults, not live sliders.
5. Test at the smallest and widest screen shape your group uses before increasing text scale or caps.

Common beginner changes:

```sqf
["Waldo_Dialogue_SecondsPerWord", 0.6],       // slower reading pace
["Waldo_Dialogue_AudienceRadius", 15],        // more nearby players see each line
["Waldo_Dialogue_ChoiceTextScale", 1.0],      // larger response text
["Waldo_Dialogue_ChoiceMaximumHeight", 0.50]  // taller list before it scrolls
```

Those are replacement rows inside the file's existing `shared` array, not lines to paste into an
NPC init field. The config changes presentation and timing globally; it does not register any NPC.
Theme selection remains in `MissionConfig\interfaceConfig.sqf`. Dialogue automatically inherits the
resolved WMP theme, its era font/colours, and each player's local colour-vision profile.

## Beginner troubleshooting

| Symptom | Check |
|---|---|
| No Talk interaction | Confirm the call is in the NPC's Init field, the NPC is alive, and you are within the configured interaction distance. With ACE loaded, look in the NPC's ACE interaction menu. |
| Another player cannot start | One speaker accepts one active caller. Wait for the current session to finish or cancel. |
| Conversation closes immediately | The speaker/caller is dead, incapacitated, deleted, replaced, outside cancellation range, or no longer owns the active server session. This is intentional fail-open behaviour. |
| Choice does nothing | Confirm its next-node ID exactly matches a defined node and its condition returns `true` on the server. |
| Recorded voice is silent | Confirm the ID exists under `CfgSounds`. Subtitles and synthetic mouth movement should still continue. |
| Text is too small or large everywhere | Adjust the relevant `*TextScale` in `dialogueConfig.sqf`; do not hard-code one NPC's control size. |
| Colours are unexpected | Check the WMP theme and local colour-vision profile in `interfaceConfig.sqf`; Dialogue intentionally inherits both. |
| A JIP player has no interaction | Run Mission Diagnostics and inspect Dialogue's ordered-client-snapshot and local-actions checks. |

The server owns registrations, session locks, choice validation, callbacks and the ordered state
version. Actions are reconciled separately on every interface client from that server snapshot,
including JIP. Presentation is sent transiently to interface clients for subtitles and lip movement;
turning and gesture commands run only where the AI is currently local, including a headless client.
A removed one-shot interaction therefore stays removed and a locality change does not move server
authority.

Mission Diagnostics reports the authoritative registry, advanced definitions and snapshot version,
plus each client's ordered-snapshot readiness, local action installation and response-panel cleanup.
Any malformed shared notification payload is rejected before Arma's strict parameter parser and is
reported with its payload and remote owner in that client's RPT.

## Migrating `val_dialogue.sqf`

Replace `execVM "val_dialogue.sqf"` with `call Waldo_fnc_SimpleDialogue`. The original parameter
order remains supported. Replace medieval arrays with the matching `DORNOW_*` archetype ID, and
remove `val_execDialogueCode`; completion code is now retained and invoked securely by WMP.

## See also

- [Feature Catalogue](Feature-Catalogue)
- [Feature Configuration Files](Feature-Configuration-Files)
- [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
