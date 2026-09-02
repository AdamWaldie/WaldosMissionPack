# Dialogue and Conversations

Two separate components — start with Simple Dialogue; only reach for Advanced
Conversations when a choice-driven, multi-node exchange is actually needed.

| You want... | Use... |
|---|---|
| An NPC to say one or several lines | **Simple Dialogue** — one call in the NPC's Eden Init field |
| Reusable ambient civilian chatter | Simple Dialogue archetype (`CIVILIAN`, `CIVILIAN_FRIENDLY`, `CIVILIAN_WARY`, or an opt-in example pack) |
| A task update after the NPC finishes | Simple Dialogue's completion-code argument |
| Questions, answers, branches or recorded voices | **Advanced Conversations** |
| Zeus to apply/author dialogue during play | The WMP Mission Flow Dialogue/Conversation ZEN modules |

Neither component is registered in `init.sqf`/`initServer.sqf` — both
self-bootstrap. Config lives only in `MissionConfig\dialogueConfig.sqf`
(presentation/timing defaults + the code-free `Waldo_Conversation_ConfigDefinitions`
array); it never registers an NPC by itself.

## Simple Dialogue

Directly in the NPC's Eden **Init** field:

```sqf
[this, "CIVILIAN"] call Waldo_fnc_SimpleDialogue;                 // random neutral archetype
[this, "The clinic is at the end of the road."] call Waldo_fnc_SimpleDialogue;  // one line
[this, [
    "Welcome to the village.",
    "The inn is beside the old bridge."
]] call Waldo_fnc_SimpleDialogue;                                  // several lines in order
```

Talk is an ACE object interaction when ACE Interact is loaded, a vanilla hold
action otherwise. Line duration is computed from word count/punctuation.
Nearby players see the line; only one caller may talk to an NPC at a time.

Compact callback form — `[target, lines, completion code, remove after use]`:

```sqf
[this, [
    "I saw the vehicle heading north.",
    "Try the old service road."
], {
    params ["_speaker", "_caller", "_context"];
    ["obj_find_vehicle", "Succeeded"] call BIS_fnc_taskSetState;
}, true] call Waldo_fnc_SimpleDialogue;
```

The completion code runs **once, server-side**, only after every line
completes; walking away/dying/losing the NPC cancels without completing it.
The original five-position form (`[this, "SPECIFIC", [lines], code, true]`)
also still works. Apply an archetype to a whole group from any member's init:
`[group this, "CIVILIAN_WARY"] call Waldo_fnc_SimpleDialogue;`. Remove later:
`[this] call Waldo_fnc_SimpleDialogueClear;`.

**Archetypes:** always-available neutral IDs are `CIVILIAN`,
`CIVILIAN_FRIENDLY`, `CIVILIAN_WARY`. Two opt-in example packs load on demand
by ID only (never loaded unless referenced, so their prose never leaks into
an unrelated mission): `MODERN_CIVILIAN`, `MODERN_CIVILIAN_FRIENDLY`,
`MODERN_CIVILIAN_WARY`, `MODERN_CIVILIAN_DISPLACED`, `MODERN_SHOPKEEPER`,
`MODERN_RURAL_RESIDENT`, `MODERN_AID_WORKER`, `MODERN_LOCAL_OFFICIAL`
(`MODERN_CIVILIANS` pack); `DORNOW_CIVILIAN`, `DORNOW_GUARD`,
`DORNOW_SHOPKEEPER`, `DORNOW_FARMER` (`MEDIEVAL_DORNOW` pack, the medieval
example).

## Advanced Conversations

Defined once (script or ZEN), then assigned to an NPC by ID. A node is
`[nodeId, lines, choices, on-enter code, automatic next node]`; a choice is
`[label, next node, condition, on-select code, optional choice id]`. Empty
next-node text ends the conversation.

```sqf
["CHECKPOINT", [
    ["START", ["Good morning. What do you need?"], [
        ["Is this road open?", "ROAD"],
        ["Nothing. Goodbye.", ""]
    ]],
    ["ROAD", ["The main road is blocked.", "Use the service track behind the depot."], []]
], "START", {
    params ["_speaker", "_caller", "_context"];
    ["obj_find_route", "Succeeded"] call BIS_fnc_taskSetState;
}] call Waldo_fnc_ConversationCreate;

[this, "CHECKPOINT"] call Waldo_fnc_ConversationAssign;
```

The starting player sees a modal response panel (clickable choices, visible
cancel) that eats gameplay input while open (no weapon-switch bleed-through).
Nearby players see each spoken line but can't choose for the initiator.
Closing/moving away/death/incapacitation/respawn/losing the active session
closes the panel client-side without waiting on the server. A green response
with a triangular marker leads to another choice node — colour + shape, so
it stays legible under any colour-vision profile; purely advisory, doesn't
pre-evaluate the destination. Up to 8 choices per node; the panel is
content-aware (compact for short labels, scrolls past the configured height
cap for long/many labels).

**Multiple speakers / recorded audio** — an enriched line replaces a plain
string:

```sqf
[speakerObject, "Subtitle text", "CfgSoundsId", soundDuration, textDurationOverride, "GestureName"]
```

Use `objNull` as speaker to keep the assigned NPC. Missing `CfgSounds`
entries log and the subtitle continues without audio. WMP drives facial
mimics/lip-sync locally and issues one `lookAt` at conversation start
(cleared at the end) rather than a per-frame turn loop — runs on whichever
machine currently owns the AI, headless client included.

Power-user direct API: `Waldo_fnc_ConversationRegister` (full HashMap
schema), `Waldo_fnc_ConversationAssign`, `Waldo_fnc_ConversationStart`,
`Waldo_fnc_ConversationCancel`, `Waldo_fnc_ConversationClear`. Conditions and
hooks receive `[_speaker, _caller, _context]` and stay server-side.

**Code-free data definitions** (`Waldo_fnc_ConversationCreateData`) — the
schema behind ZEN and `MissionConfig` authoring: `[id, nodes, startNode]`;
nodes are `[nodeId, lines, choices, automaticNextNode]`; lines are
`[text, CfgSounds id, sound duration, text duration override, gesture]`;
choices are `[label, destination node, choice id]`. IDs: uppercase
letters/numbers/underscore only. Paste **Export Config** output from the ZEN
author into the `Waldo_Conversation_ConfigDefinitions` array in
`MissionConfig\dialogueConfig.sqf` (the loader registers these automatically
after config load); paste **Export Script** output into `initServer.sqf`
for a standalone `Waldo_fnc_ConversationCreate` call you then extend with
conditions/hooks by hand.

## Zeus Enhanced ("WMP Mission Flow")

- **Dialogue - Apply Simple Archetype**
- **Dialogue - Assign Simple Lines** (lines separated by `|`)
- **Dialogue - Clear**
- **Conversation: Assign** — place on the NPC; requests the current ID
  catalogue from the server every time it opens (JIP/late-registered IDs
  always current). Private conditions/hooks never replicate to curators.
- **Conversation: Author** — the beginner-friendly branching builder. Place
  in empty space to build/save for later, or directly on a living NPC to
  also get **Save + Give**. Workflow: (1) add **Conversation Parts** — one
  part per moment; (2) write **What the NPC Says** per part; (3) add
  **What the Player Can Say** answers, each pointing at a part or **End**;
  (4) **Check**, fix anything flagged **Needs Fixing**, then **Save for
  Zeus** or a **Save + Give** button. Impossible actions (Remove on the only
  part, Up on the first item, etc.) are visibly disabled. Renaming a
  conversation/part updates every route pointing at it immediately.
  **One Use Only** removes the assignment after it fires once. Saving/
  applying an already-registered name updates that definition for future
  sessions — a session already in progress keeps its started snapshot. The
  editor's schema is deliberately serialisable-only: no typed SQF,
  conditions, callbacks, or arbitrary object refs — use the standalone
  script export for those power-user needs.

## Timing / limits (`MissionConfig\dialogueConfig.sqf`, `shared` array)

```sqf
["Waldo_Dialogue_SecondsPerWord", 0.5],          // MISSION MAKER: reading pace
["Waldo_Dialogue_MinimumLineSeconds", 1.5],
["Waldo_Dialogue_MaximumLineSeconds", 15],
["Waldo_Dialogue_CommaPause", 0.12],              // ADVANCED
["Waldo_Dialogue_TerminalPause", 0.25],           // ADVANCED
["Waldo_Dialogue_AudienceRadius", 10],            // MISSION MAKER: who sees/hears a line
["Waldo_Dialogue_InteractionDistance", 3],
["Waldo_Dialogue_CancelDistance", 6],
["Waldo_Dialogue_SubtitleMinimumWidth", 0.22],    // ADVANCED — safe-zone FRACTIONS, not pixels
["Waldo_Dialogue_SubtitleMaximumWidth", 0.46],
["Waldo_Dialogue_SubtitleMaximumHeight", 0.20],
["Waldo_Dialogue_SubtitleTextScale", 0.90],
["Waldo_Dialogue_ChoiceMinimumWidth", 0.20],
["Waldo_Dialogue_ChoiceMaximumWidth", 0.50],
["Waldo_Dialogue_ChoiceMaximumHeight", 0.50],
["Waldo_Dialogue_ChoiceMinimumRowHeight", ...],
["Waldo_Dialogue_ChoiceTextScale", 1.0],
["Waldo_Conversation_ConfigDefinitions", []]      // ZEN Conversation Author "Export Config" rows land here
```

These are guarded startup defaults, not live sliders — edit the value only,
keep widths/heights as safe-zone fractions, restart/rebuild to apply.
Simple Dialogue permits 32 lines of 500 characters; Advanced Conversations
permit 128 nodes, 16 lines and 8 choices per node, 256 transitions/session.
Dialogue automatically inherits the resolved WMP theme (era font/colours,
`interfaceConfig.sqf`) and each player's local colour-vision profile — never
set colour-vision mission-wide (see `references/ui-themes.md`).

## Gotchas

- No Talk interaction → confirm the call is in the NPC's Init field, the NPC
  is alive, and the player is within `Waldo_Dialogue_InteractionDistance`.
- Choice does nothing → its next-node ID must exactly match a defined node,
  and its condition must evaluate `true` server-side.
- Recorded voice silent → confirm the ID exists under `CfgSounds`; subtitle
  and synthetic mouth movement still continue regardless.
- A JIP player sees no interaction → run Mission Diagnostics and check
  Dialogue's ordered-client-snapshot / local-actions rows.
- Migrating an old `execVM "val_dialogue.sqf"` script: replace with
  `call Waldo_fnc_SimpleDialogue` (same param order), use the matching
  `DORNOW_*` archetype for medieval arrays, and drop
  `val_execDialogueCode` — completion code is now retained/invoked securely
  by WMP itself.

See `wiki/Dialogue-And-Conversations.md` for the full response-panel sizing
behaviour, multiplayer locality detail, and the full troubleshooting table.
