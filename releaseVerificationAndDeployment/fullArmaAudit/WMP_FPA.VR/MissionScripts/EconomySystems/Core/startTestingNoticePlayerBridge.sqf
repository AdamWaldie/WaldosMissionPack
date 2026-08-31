/*
 * Author: WaldoTheWarfighter
 * Installs the Economy testing-notice action for current players and future player lifecycles.
 *
 * Locality/authority: server only. Repeat/JIP behaviour: repeat-safe; current players are reconciled
 * once, then engine PlayerConnected and EntityRespawned events install the action on new player
 * objects. The short connection worker exists only while Arma resolves the joining player's object.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true when the bridge is active; false outside server authority or while Economy is inactive.
 *
 * Current callers: economyInit after authoritative Economy startup.
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_startTestingNoticePlayerBridge;
 */

if !([] call Waldo_fnc_EcoCore_canRunBackgroundAuthority) exitWith {false};
if !([] call Waldo_fnc_EcoCore_isModuleActive) exitWith {false};
if (missionNamespace getVariable ["WaldoEcoCore_TestingNoticePlayerBridgeStarted", false]) exitWith {true};

missionNamespace setVariable ["WaldoEcoCore_TestingNoticePlayerBridgeStarted", true];

private _connectedHandler = addMissionEventHandler ["PlayerConnected", {
    params ["_id", "_uid", "_name", "_jip", "_ownerId"];

    [_ownerId] spawn {
        params ["_ownerId"];

        private _deadline = diag_tickTime + 30;
        private _unit = objNull;

        waitUntil {
            uiSleep 0.25;

            private _playerIndex = allPlayers findIf {owner _x == _ownerId};
            if (_playerIndex >= 0) then {
                _unit = allPlayers select _playerIndex;
            };

            !isNull _unit
                || {diag_tickTime >= _deadline}
                || {!([] call Waldo_fnc_EcoCore_isModuleActive)}
        };

        if (!isNull _unit) then {
            [_unit] call Waldo_fnc_EcoCore_installTestingNoticeActionServer;
        };
    };
}];

private _respawnHandler = addMissionEventHandler ["EntityRespawned", {
    params ["_newEntity"];

    if (isPlayer _newEntity) then {
        [_newEntity] call Waldo_fnc_EcoCore_installTestingNoticeActionServer;
    };
}];

missionNamespace setVariable ["WaldoEcoCore_TestingNoticePlayerConnectedEH", _connectedHandler];
missionNamespace setVariable ["WaldoEcoCore_TestingNoticeRespawnEH", _respawnHandler];

// Install the handlers first so a player cannot join between the initial reconciliation and the
// lifecycle subscription. Repeat-safe action publication tolerates a player appearing in both.
{
    [_x] call Waldo_fnc_EcoCore_installTestingNoticeActionServer;
} forEach allPlayers;

true
