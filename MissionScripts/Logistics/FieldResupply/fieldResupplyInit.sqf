/*
 * Author: Waldo
 * Installs the repeat-safe local carrier deployment action.
 *
 * Arguments: None
 * Return Value: Boolean
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", isServer]) exitWith {
    [] spawn {waitUntil {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]}; [] call Waldo_fnc_FieldResupplyInit};
    true
};
if !(missionNamespace getVariable ["Waldo_FieldResupply_Enable", false]) exitWith {false};
if (player getVariable ["Waldo_FieldResupply_ActionInstalled", false]) exitWith {true};
private _action = player addAction [
    "Deploy Field Resupply",
    {[player, "DEPLOY", []] remoteExecCall ["Waldo_fnc_FieldResupplyServerHandle", 2]},
    [], 1.5, false, true, "",
    "vehicle player == player && {player getVariable ['Waldo_FieldResupply_Crates', 0] > 0}", 3
];
player setVariable ["Waldo_FieldResupply_Action", _action];
player setVariable ["Waldo_FieldResupply_ActionInstalled", true];
if !(missionNamespace getVariable ["Waldo_FieldResupply_RespawnHandler", false]) then {
    missionNamespace setVariable ["Waldo_FieldResupply_RespawnHandler", true];
    addMissionEventHandler ["EntityRespawned", {
        params ["_newEntity", "_oldEntity"];
        if (_newEntity isEqualTo player) then {
            if (missionNamespace getVariable ["Waldo_FieldResupply_RetainOnRespawn", true]) then {
                _newEntity setVariable ["Waldo_FieldResupply_MaxCrates", _oldEntity getVariable ["Waldo_FieldResupply_MaxCrates", 0], true];
                _newEntity setVariable ["Waldo_FieldResupply_Crates", _oldEntity getVariable ["Waldo_FieldResupply_Crates", 0], true];
            };
            [] call Waldo_fnc_FieldResupplyInit;
        };
    }];
};
true
