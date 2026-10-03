/*
 * Author: WaldoTheWarfighter
 * Resolves a WMP UI channel's display position from caller default, mission setting and any
 * player override that the mission maker allowed.
 * Locality and authority: Reads published mission defaults and, on an interface client,
 * local profile choices. Repeated calls are read-only; JIP uses current published defaults
 * and that player's own profile preferences.
 * Arguments: 0: channel <STRING> ("MISSION"); 1: requested placement <STRING> ("TOP");
 *   2: permit local override lookup <BOOL> (false).
 * Return Value: <STRING> one of TOP, TOP_RIGHT, CENTER, BOTTOM_LEFT, BOTTOM_CENTER,
 *   BOTTOM_RIGHT; invalid values fall back to TOP.
 * Current callers: WMP notification placement and specialist UI layout helpers.
 * Example: ["QUARTERMASTER", "TOP_RIGHT", true] call Waldo_fnc_ResolveUiPanelPlacement;
 * Result: Returns the mission choice, or this player's permitted override when one exists.
 */
params [["_channel", "MISSION", [""]], ["_requested", "TOP", [""]], ["_allowLocalOverride", false, [true]]];
_channel = toUpper _channel;
private _placement = toUpper _requested;
private _valid = ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"];
if !(_placement in _valid) then {_placement = "TOP";};
private _settings = missionNamespace getVariable ["Waldo_UI_PanelPlacements", []];
private _index = _settings findIf {(_x param [0, ""]) isEqualTo _channel};
private _missionAllows = false;
if (_index >= 0) then {
    private _entry = _settings select _index;
    _placement = _entry param [1, _placement];
    _missionAllows = _entry param [2, false];
};
if (_allowLocalOverride && {_missionAllows} && {hasInterface}) then {
    private _overrides = profileNamespace getVariable ["Waldo_UI_LocalPanelPlacements", []];
    private _overrideIndex = _overrides findIf {(_x param [0, ""]) isEqualTo _channel};
    if (_overrideIndex >= 0) then {_placement = (_overrides select _overrideIndex) param [1, _placement];};
};
if !(_placement in _valid) then {_placement = "TOP";};
_placement
