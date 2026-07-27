/*
 * Sets a mission-authored default placement for one WMP UI channel.
 * Call on the server with publish=true, or from initPlayerLocal for a local mission.
 *
 * Arguments: [channel, placement, allowLocalPlayerOverride, publish]
 * Return: validated placement
 */
params [
    ["_channel", "MISSION", [""]],
    ["_placement", "TOP", [""]],
    ["_allowLocalPlayerOverride", false, [true]],
    ["_publish", isServer, [true]]
];

_channel = toUpper _channel;
_placement = toUpper _placement;
private _valid = ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_RIGHT"];
if !(_placement in _valid) then {_placement = "TOP";};

private _settings = +(missionNamespace getVariable ["Waldo_UI_PanelPlacements", []]);
private _index = _settings findIf {(_x param [0, ""]) isEqualTo _channel};
private _entry = [_channel, _placement, _allowLocalPlayerOverride];
if (_index < 0) then {_settings pushBack _entry;} else {_settings set [_index, _entry];};
missionNamespace setVariable ["Waldo_UI_PanelPlacements", _settings, _publish];
_placement
