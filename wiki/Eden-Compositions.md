# Eden compositions

> **Use this page when:** you want a pre-placed, editable example instead of building a supported
> WMP setup from individual Eden objects.

Install the matching WMP release in your mission before placing a composition. The composition
archive contains Eden objects and their setup calls. It does not contain the pack's scripts.

Eden groups the examples under Foundation, Logistics, Air Operations, Combat Systems, Interface,
Mission Systems and Mission Tools. The pack's `WMP_Compositions/README.md` lists every composition.

## Place and test an example

1. Place the composition on open ground. If its name ends in **Minimal**, start with that version.
2. Read the Eden comment next to the objects. Set any named feature flag in `MissionConfig`.
3. Keep the objects spaced as placed. Vehicles may need room, simulation or a crew.
4. Preview the mission. Check the player action or effect described in the comment.
5. Change one Init-field option at a time, using the wiki link in the comment to check its values.

If no action appears, check the feature flag first. Then run [Mission Diagnostics](Mission-Diagnostics)
and read the server RPT. Copying a composition does not turn on a disabled feature.

## Minimal and Full examples

**Minimal** uses the required arguments and the pack's defaults. **Full** shows the optional
arguments on the same objects. Use the Full version when you need to change those options. Features
with no useful optional arguments have one unsuffixed example.

## Locality rule

Leave the supplied Init calls in place. WMP registers the objects and gives joining players their
actions. Some calls forward to the server. Others run on the server's copy of the Eden object. Add
an `isServer` wrapper only when the linked feature page asks for one. The Prowler example guards its
seat-point setting because that value belongs to the server.

Keep the wiki URL in an Eden comment so you can check the object's options after moving it.

## Notification Trigger

The **Notification Trigger** fires once when any player enters its 25 m area. Edit **On Activation**
to change its title, message, type or recipients. Keep **Server Only** enabled in multiplayer so
players receive one notification. See [Custom WMP UI Notifications](Custom-UI-Notifications).

## Features without a placed example

Dynamic AA, Dynamic AO Generation and Airborne Gunship Support have Eden compositions. Their setup
functions send client-side Eden calls to the server. Generated paradrop zones work differently:
`Waldo_fnc_ParadropCreateDropZone` creates its own aircraft and crew when called. Use `initServer.sqf`
or the **Dynamic Paradrop** ZEN module for that. For an aircraft already placed with its crew, use
[Halo and Static-Line Paradrop Examples](Vehicle-Actions-&-Paradrop).

Player accessibility, treatment feedback, persistence enablement, UI themes, rally state, tree
felling and automatic AI handlers use configuration or scripted setup instead of a placed object.
The **Persistence Object Example** registers one particular object for persistence. Use the linked
feature page or a focused ZEN module for other changes.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature setup](Feature-Setup-and-Activation)
