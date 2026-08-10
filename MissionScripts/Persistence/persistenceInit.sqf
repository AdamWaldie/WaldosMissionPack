/*
 * Author: WaldoTheWarfighter
 * Starts optional, repeat-safe player and world-object persistence.
 * The server owns database access; clients only capture/apply their local player state.
 * Player clients publish an explicit load state and cannot begin automatic writes until the server
 * answers FOUND/NONE and any required ACRE restore/baseline has completed. A missing response fails
 * open for gameplay after 30 seconds while persistence writes remain closed, preventing an unread
 * database record from being overwritten. JIP clients perform the same bounded handshake.
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
    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
        };
        if (missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {[] call Waldo_fnc_PersistenceInit};
    };
    true
};
if !(missionNamespace getVariable ["Waldo_Persistence_Enable", false]) exitWith {
    if (hasInterface) then {
        missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "DISABLED"];
        missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", true];
    };
    false
};

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
            !isNull player
        };
        // This function is called only after the ordered runtime snapshot. At this point false is a
        // resolved dependency-gate result, not an unknown startup default, so do not delay ACRE.
        if !(missionNamespace getVariable ["Waldo_Persistence_Active", false]) exitWith {
            missionNamespace setVariable ["Waldo_Persistence_ClientStarted", false];
            missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "FAILED"];
            missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", false];
            ["PERSISTENCE_UNAVAILABLE", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
        };

        private _loadToken = (missionNamespace getVariable ["Waldo_Persistence_PlayerLoadToken", 0]) + 1;
        missionNamespace setVariable ["Waldo_Persistence_PlayerLoadToken", _loadToken];
        missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "PENDING"];
        missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", false];
        ["LOAD_PLAYER", []] remoteExecCall ["Waldo_fnc_PersistenceServerHandle", 2];

        [_loadToken] spawn {
            params ["_loadToken"];
            private _deadline = diag_tickTime + 30;
            waitUntil {
                sleep 0.25;
                (missionNamespace getVariable ["Waldo_Persistence_PlayerLoadToken", -1]) != _loadToken
                    || {(missionNamespace getVariable ["Waldo_Persistence_PlayerLoadState", "FAILED"]) != "PENDING"}
                    || {diag_tickTime >= _deadline}
            };
            if (
                (missionNamespace getVariable ["Waldo_Persistence_PlayerLoadToken", -1]) == _loadToken
                && {(missionNamespace getVariable ["Waldo_Persistence_PlayerLoadState", "FAILED"]) == "PENDING"}
            ) then {
                missionNamespace setVariable ["Waldo_Persistence_PlayerLoadState", "FAILED"];
                missionNamespace setVariable ["Waldo_Persistence_PlayerSaveReady", false];
                diag_log "[WMP PERSISTENCE] Player load timed out; ACRE baseline released and automatic persistence writes remain disabled.";
                ["PERSISTENCE LOAD", "The saved player state did not arrive. Mission systems will continue, but automatic persistence saving is disabled to protect the existing record.", "WARNING", "PERSISTENCE_LOAD_TIMEOUT"] call Waldo_fnc_FeatureNotifyLocal;
                ["PERSISTENCE_TIMEOUT", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
            };
        };

        private _interval = (missionNamespace getVariable ["Waldo_Persistence_PlayerSaveInterval", 60]) max 10;
        private _handle = [_interval] spawn {
            params ["_interval"];
            waitUntil {
                sleep 0.25;
                missionNamespace getVariable ["Waldo_Persistence_PlayerSaveReady", false]
                    || {(missionNamespace getVariable ["Waldo_Persistence_PlayerLoadState", "FAILED"]) == "FAILED"}
            };
            if !(missionNamespace getVariable ["Waldo_Persistence_PlayerSaveReady", false]) exitWith {
                diag_log "[WMP PERSISTENCE] Automatic player saves were not started because the initial load did not resolve safely.";
            };
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
