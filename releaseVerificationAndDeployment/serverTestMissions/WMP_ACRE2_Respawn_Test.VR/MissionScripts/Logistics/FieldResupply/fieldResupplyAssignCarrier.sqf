/*
 * Author: WaldoTheWarfighter
 * Assigns Field Resupply capacity and current portable-crate stock to an infantry unit.
 *
 * The server owns assignment and respawn carry-over. A curator may invoke the public function
 * remotely; ordinary remote clients are rejected. Carrier variables are public so the owning
 * client can evaluate interaction conditions, while the server remains authoritative for every
 * change. A single server respawn handler transfers carrier state when configured and asks the new
 * owner to reinstall its local controls.
 *
 * Arguments:
 * 0: unit <OBJECT> - infantry unit that may carry and deploy field-resupply crates.
 * 1: current crates <NUMBER> - starting portable crates (default 1).
 * 2: maximum crates <NUMBER> - carrier capacity (default 2).
 *
 * Return Value:
 * Boolean - true when the request was forwarded or assignment succeeded; otherwise false.
 *
 * Example:
 * if (isServer) then {[this, 3, 3] call Waldo_fnc_FieldResupplyAssignCarrier;};
 *
 * Current callers: Field Resupply ZEN assignment, audit carrier station and mission-maker setup.
 */

params [["_unit", objNull, [objNull]], ["_crates", 1, [0]], ["_maximum", 2, [0]]];
if !(isServer) exitWith {
    [_unit, _crates, _maximum] remoteExecCall ["Waldo_fnc_FieldResupplyAssignCarrier", 2];
    true
};
if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {false};
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {false};
};

_maximum = round (_maximum max 0);
_unit setVariable ["Waldo_FieldResupply_MaxCrates", _maximum, true];
_unit setVariable ["Waldo_FieldResupply_Crates", (round _crates max 0) min _maximum, true];
missionNamespace setVariable ["Waldo_FieldResupply_Enable", true, true];

if !(missionNamespace getVariable ["Waldo_FieldResupply_ServerRespawnHandler", false]) then {
    missionNamespace setVariable ["Waldo_FieldResupply_ServerRespawnHandler", true];
    addMissionEventHandler ["EntityRespawned", {
        params ["_newEntity", "_oldEntity"];
        if !(isServer) exitWith {};
        private _maximum = _oldEntity getVariable ["Waldo_FieldResupply_MaxCrates", 0];
        if (_maximum <= 0) exitWith {};
        if (missionNamespace getVariable ["Waldo_FieldResupply_RetainOnRespawn", true]) then {
            _newEntity setVariable ["Waldo_FieldResupply_MaxCrates", _maximum, true];
            _newEntity setVariable [
                "Waldo_FieldResupply_Crates",
                (_oldEntity getVariable ["Waldo_FieldResupply_Crates", 0]) min _maximum,
                true
            ];
        };
        [] remoteExecCall ["Waldo_fnc_FieldResupplyInit", owner _newEntity];
    }];
};

[[["Waldo_FieldResupply_Enable", true]], false] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", owner _unit];
[] remoteExecCall ["Waldo_fnc_FieldResupplyInit", owner _unit];
true
