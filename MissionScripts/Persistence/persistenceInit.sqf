/*
 * Author: Waldo
 * Starts optional, repeat-safe player and world-object persistence.
 * The server owns database access; clients only capture/apply their local player state.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when startup was accepted on this machine
 *
 * Example:
 * [] spawn Waldo_fnc_PersistenceInit;
 */

if (!isServer && {hasInterface} && {!(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false])}) exitWith {
    [] spawn {waitUntil {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]}; [] call Waldo_fnc_PersistenceInit};
    true
};
if !(missionNamespace getVariable ["Waldo_Persistence_Enable", false]) exitWith {false};

if (isServer) then {
    if (missionNamespace getVariable ["Waldo_Persistence_ServerStarted", false]) exitWith {true};

    if !([] call Waldo_fnc_PersistenceDependencyAvailable) exitWith {
        missionNamespace setVariable ["Waldo_Persistence_Active", false, true];
        diag_log "[WMP PERSISTENCE] Disabled: INIDBI2 runtime was not detected or could not be initialised.";
        false
    };

    missionNamespace setVariable ["Waldo_Persistence_ServerStarted", true];
    missionNamespace setVariable ["Waldo_Persistence_Active", true, true];
    missionNamespace setVariable ["Waldo_Persistence_ObjectRegistry", []];

    {
        _x call Waldo_fnc_PersistenceRegisterObject;
    } forEach +(missionNamespace getVariable ["Waldo_Persistence_PendingObjects", []]);
    missionNamespace setVariable ["Waldo_Persistence_PendingObjects", []];

    private _interval = (missionNamespace getVariable ["Waldo_Persistence_ObjectSaveInterval", 60]) max 10;
    private _handle = [_interval] spawn {
        params ["_interval"];
        while {missionNamespace getVariable ["Waldo_Persistence_Active", false]} do {
            sleep _interval;
            {
                _x params ["_object", "_key", "_options"];
                if (!isNull _object) then {
                    [_object, _key, _options] call Waldo_fnc_PersistenceSaveObject;
                };
            } forEach +(missionNamespace getVariable ["Waldo_Persistence_ObjectRegistry", []]);
        };
    };
    missionNamespace setVariable ["Waldo_Persistence_ServerLoop", _handle];
    diag_log "[WMP PERSISTENCE] Server persistence is active.";
};

if (hasInterface) then {
    if (missionNamespace getVariable ["Waldo_Persistence_ClientStarted", false]) exitWith {true};
    missionNamespace setVariable ["Waldo_Persistence_ClientStarted", true];

    [] spawn {
        waitUntil {
            sleep 0.25;
            !isNull player && {
                missionNamespace getVariable ["Waldo_Persistence_Active", false]
                || {time > 20}
            }
        };
        if !(missionNamespace getVariable ["Waldo_Persistence_Active", false]) exitWith {
            missionNamespace setVariable ["Waldo_Persistence_ClientStarted", false];
        };

        ["LOAD_PLAYER", []] remoteExecCall ["Waldo_fnc_PersistenceServerHandle", 2];

        private _interval = (missionNamespace getVariable ["Waldo_Persistence_PlayerSaveInterval", 60]) max 10;
        private _handle = [_interval] spawn {
            params ["_interval"];
            while {missionNamespace getVariable ["Waldo_Persistence_Active", false]} do {
                sleep _interval;
                if (alive player) then {
                    [] call Waldo_fnc_PersistenceSavePlayerLocal;
                };
            };
        };
        missionNamespace setVariable ["Waldo_Persistence_ClientLoop", _handle];
    };
};

true
