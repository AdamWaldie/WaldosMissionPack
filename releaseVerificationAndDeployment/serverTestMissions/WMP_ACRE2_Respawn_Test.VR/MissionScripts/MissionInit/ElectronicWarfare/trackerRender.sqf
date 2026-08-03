/*
 * Author: WaldoTheWarfighter
 * Client render loop for signal trackers. Keeps a set of local map markers in sync with the
 * broadcast tracker registry, showing only the trackers whose tracking side is "ALL" or the local
 * player's side - so a tracker is visible to the side that planted it and stays hidden from the
 * target's side. Markers are local (createMarkerLocal), so nothing leaks over the network. Creates,
 * moves and deletes markers as trackers are planted, move and are removed. One instance per client.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_TrackerRender;   // started from Waldo_fnc_JammingInit
 */

if !(hasInterface) exitWith {};
if (missionNamespace getVariable ["Waldo_Tracker_RenderRunning", false]) exitWith {};
missionNamespace setVariable ["Waldo_Tracker_RenderRunning", true];

[] spawn {
    private _live = [];   // ids currently drawn locally

    while {true} do {
        private _registry = missionNamespace getVariable ["Waldo_Tracker_Registry", []];
        private _wanted = [];

        {
            _x params ["_id", "_tgt", "_side", "_label", "_active"];
            private _see = (_side isEqualType "") || {_side == side player};
            if (_active && _see && {!isNull _tgt} && {alive _tgt}) then {
                _wanted pushBack _id;
                private _mk = format ["Waldo_TrkL_%1", _id];
                if !(_id in _live) then {
                    createMarkerLocal [_mk, getPosATL _tgt];
                    _mk setMarkerTypeLocal "mil_triangle";
                    _mk setMarkerColorLocal "ColorRed";
                    _mk setMarkerTextLocal _label;
                    _mk setMarkerSizeLocal [0.8, 0.8];
                };
                _mk setMarkerPosLocal (getPosATL _tgt);
                _mk setMarkerDirLocal (getDir _tgt);
            };
        } forEach _registry;

        // Drop markers whose tracker is gone or no longer visible.
        {
            if !(_x in _wanted) then {
                deleteMarkerLocal (format ["Waldo_TrkL_%1", _x]);
            };
        } forEach _live;

        _live = _wanted;
        sleep 2;
    };
};
