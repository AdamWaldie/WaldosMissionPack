/*
 * Sets a local player's placement override when the mission has allowed it.
 * Arguments: [channel, placement, persist]
 * Return: BOOL
 */
if (!hasInterface) exitWith {false};
params [["_channel", "MISSION", [""]], ["_placement", "TOP", [""]], ["_persist", true, [true]]];
_channel = toUpper _channel;
_placement = toUpper _placement;
if !(_placement in ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_RIGHT"]) exitWith {false};
private _settings = missionNamespace getVariable ["Waldo_UI_PanelPlacements", []];
private _index = _settings findIf {(_x param [0, ""]) isEqualTo _channel};
if (_index < 0 || {!((_settings select _index) param [2, false])}) exitWith {false};
private _overrides = +(profileNamespace getVariable ["Waldo_UI_LocalPanelPlacements", []]);
private _overrideIndex = _overrides findIf {(_x param [0, ""]) isEqualTo _channel};
if (_overrideIndex < 0) then {_overrides pushBack [_channel, _placement];} else {_overrides set [_overrideIndex, [_channel, _placement]];};
profileNamespace setVariable ["Waldo_UI_LocalPanelPlacements", _overrides];
if (_persist) then {saveProfileNamespace;};
true
