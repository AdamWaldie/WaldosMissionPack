/*
 * Author: WaldoTheWarfighter
 * Sets a player's UI-channel placement override only when the mission maker permits it.
 * Locality and authority: Interface-client only. This player's profileNamespace stores
 * the override, optionally to disk; server defaults remain unchanged. Repeating the call
 * replaces that channel's override, and a later JIP session reads the player's own profile.
 * Arguments: 0: channel <STRING> ("MISSION"); 1: placement <STRING> ("TOP");
 *   2: persist to profile <BOOL> (true).
 * Return Value: <BOOL> true when a permitted placement was stored; false otherwise.
 * Current callers: Mission-maker client-side UI setup (see Custom UI Notifications wiki).
 * Example: ["QUARTERMASTER", "BOTTOM_RIGHT", true]
 *   call Waldo_fnc_SetLocalUiPanelPlacement;
 * Result: This player's permitted QUARTERMASTER cards use BOTTOM_RIGHT on later placement.
 */
if (!hasInterface) exitWith {false};
params [["_channel", "MISSION", [""]], ["_placement", "TOP", [""]], ["_persist", true, [true]]];
_channel = toUpper _channel;
_placement = toUpper _placement;
if !(_placement in ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"]) exitWith {false};
private _settings = missionNamespace getVariable ["Waldo_UI_PanelPlacements", []];
private _index = _settings findIf {(_x param [0, ""]) isEqualTo _channel};
if (_index < 0 || {!((_settings select _index) param [2, false])}) exitWith {false};
private _overrides = +(profileNamespace getVariable ["Waldo_UI_LocalPanelPlacements", []]);
private _overrideIndex = _overrides findIf {(_x param [0, ""]) isEqualTo _channel};
if (_overrideIndex < 0) then {_overrides pushBack [_channel, _placement];} else {_overrides set [_overrideIndex, [_channel, _placement]];};
profileNamespace setVariable ["Waldo_UI_LocalPanelPlacements", _overrides];
if (_persist) then {saveProfileNamespace;};
true
