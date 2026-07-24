/*
 * Author: Waldo
 * Server authority for UAV/UGV jamming. While any jammer flagged to jam UAVs exists, this checks
 * every drone against the jammer fields and, for drones inside one, freezes their autonomous AI
 * (they stop flying/driving and hunting) and broadcasts a "jammed" flag on the drone so the
 * controlling player's client can react. Restores the AI when the drone leaves the field. Only the
 * server runs this so a drone is judged once, and it only does work when a UAV-jamming jammer is
 * actually placed. Player-controlled drones are handled client-side (Waldo_fnc_JammingUavClient).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_JammingUavServer;
 */

if !(isServer) exitWith {};
if (missionNamespace getVariable ["Waldo_Jamming_UavServerRunning", false]) exitWith {};
missionNamespace setVariable ["Waldo_Jamming_UavServerRunning", true];

[] spawn {
    while {true} do {
        private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
        // Only do the drone sweep if at least one active jammer is set to jam UAVs.
        private _hasUavJammer = (_registry findIf {
            (_x select 7) && {(count _x > 11) && {_x select 11}}
        }) >= 0;

        if (_hasUavJammer) then {
            private _drones = vehicles select { alive _x && {unitIsUAV _x} };
            {
                private _drone = _x;
                private _f = [getPosASL _drone, side _drone, -1, -1, true] call Waldo_fnc_JammingFactor;
                private _jammed = _f > 0;
                private _was = _drone getVariable ["Waldo_Jamming_UAVJammed", false];

                if (_jammed && {!_was}) then {
                    _drone setVariable ["Waldo_Jamming_UAVJammed", true, true];
                    {
                        _x disableAI "MOVE";
                        _x disableAI "TARGET";
                        _x disableAI "AUTOTARGET";
                        _x disableAI "FSM";
                    } forEach (crew _drone);
                };
                if (!_jammed && {_was}) then {
                    _drone setVariable ["Waldo_Jamming_UAVJammed", false, true];
                    {
                        _x enableAI "MOVE";
                        _x enableAI "TARGET";
                        _x enableAI "AUTOTARGET";
                        _x enableAI "FSM";
                    } forEach (crew _drone);
                };
            } forEach _drones;
        };

        sleep 2;
    };
};

diag_log "[WMP JAM] UAV jamming server authority started.";
