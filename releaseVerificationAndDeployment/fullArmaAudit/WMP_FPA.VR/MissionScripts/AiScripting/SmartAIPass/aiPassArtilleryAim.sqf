/*
 * Author: WaldoTheWarfighter
 * Chooses a bounded ranging aim point. Player positions are used only to reject unsafe opening aim points.
 * Locality/authority: documented guards enforce server coordination and owner-local execution.
 * Repeat/JIP: mission tokens reject stale work; server state survives HC migration, not restart.
 * Arguments: 0: mission <HASHMAP>, required; keys fix, battery, offset, bearing, fired, mode, magazine.
 * Return Value: Array ATL aim, or [] if all eight candidates fail.
 * Current callers: ArtilleryMissionStep.
 * Example: private _aim = [_mission] call Waldo_fnc_AIPassArtilleryAim;
 */
params ["_mission"];
(_mission get "fix") params ["_centre", "_error"];
private _battery = _mission get "battery";
private _opening = (_mission get "fired") == 0 && {(_mission get "mode") != "SMOKE"};
private _safe = (missionNamespace getVariable ["Waldo_AIPass_Artillery_OpeningSafeDistance", 200]) max 100;
private _buffer = (missionNamespace getVariable ["Waldo_AIPass_Artillery_OpeningBuffer", 100]) max 50;
private _players = if (_opening) then {(allPlayers select {alive _x && {!(_x isKindOf "HeadlessClient_F")}}) apply {getPosATL vehicle _x}} else {[]};
private _radius = (_mission get "offset") + (_error max 0);
if (_opening) then {_radius = _radius max (_safe + _buffer)};
private _aim = [];
for "_attempt" from 0 to 7 do {
    private _candidate = _centre getPos [_radius + random 30, (_mission get "bearing") + _attempt * 45];
    if ((!_opening || {_players findIf {_x distance2D _candidate < _safe + _buffer} < 0})
        && {_candidate inRangeOfArtillery [[_battery], _mission get "magazine"]}) exitWith {_aim = _candidate};
};
_aim
