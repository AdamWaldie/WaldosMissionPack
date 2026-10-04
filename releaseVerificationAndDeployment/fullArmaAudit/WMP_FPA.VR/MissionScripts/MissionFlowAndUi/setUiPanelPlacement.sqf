/*
 * Author: WaldoTheWarfighter
 * Sets a mission-authored default placement for one WMP UI channel.
 * Call on the server with publish=true, or from initPlayerLocal for a local mission.
 *
 * Locality and authority: Normally called on the server with publication enabled; a local
 * mission can set its own value. Reusing a channel replaces its entry, and published settings
 * provide the current default to JIP clients.
 * Arguments: 0: channel <STRING> ("MISSION"); 1: placement <STRING> ("TOP");
 *   2: allow player override <BOOL> (false); 3: publish <BOOL> (isServer).
 * Return Value: <STRING> validated placement; invalid choices become "TOP".
 * Current callers: Mission-maker server UI configuration (see Custom UI Notifications wiki).
 * Example: ["QUARTERMASTER", "TOP_RIGHT", true, true]
 *   call Waldo_fnc_SetUiPanelPlacement;
 * Result: QUARTERMASTER cards default to TOP_RIGHT, with local overrides allowed.
 */
params [
    ["_channel", "MISSION", [""]],
    ["_placement", "TOP", [""]],
    ["_allowLocalPlayerOverride", false, [true]],
    ["_publish", isServer, [true]]
];

_channel = toUpper _channel;
_placement = toUpper _placement;
private _valid = ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"];
if !(_placement in _valid) then {_placement = "TOP";};

private _settings = +(missionNamespace getVariable ["Waldo_UI_PanelPlacements", []]);
private _index = _settings findIf {(_x param [0, ""]) isEqualTo _channel};
private _entry = [_channel, _placement, _allowLocalPlayerOverride];
if (_index < 0) then {_settings pushBack _entry;} else {_settings set [_index, _entry];};
missionNamespace setVariable ["Waldo_UI_PanelPlacements", _settings, _publish];
_placement
