/*
 * Author: WaldoTheWarfighter
 * Starts event-driven publication of the local player's Ground Command identity.
 *
 * Locality/authority: interface client only. Repeat/JIP behaviour: repeat-safe; publishes once for
 * initial/JIP setup, follows CBA player-unit replacement for respawn/team switch, and uses bounded
 * UID readiness retries. The removable event id and epoch support purge/re-enable cleanup.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true when active/already active; false outside an active interface client.
 *
 * Current callers: economyInit.
 *
 * Example:
 * [] call Waldo_fnc_EcoCommand_startLocalGroundCommandIdentityService;
 */

if (!hasInterface || {!([] call Waldo_fnc_EcoCore_isModuleActive)}) exitWith {false};
if (missionNamespace getVariable ["WaldoEcoCommand_LocalIdentityServiceStarted", false]) exitWith {true};

private _epoch = (missionNamespace getVariable ["WaldoEcoCommand_LocalIdentityServiceEpoch", 0]) + 1;
missionNamespace setVariable ["WaldoEcoCommand_LocalIdentityServiceEpoch", _epoch];
missionNamespace setVariable ["WaldoEcoCommand_LocalIdentityServiceStarted", true];

private _eventId = [
    "unit",
    {
        [] call Waldo_fnc_EcoCommand_requestLocalGroundCommandIdentityRefresh;
    },
    false
] call CBA_fnc_addPlayerEventHandler;
missionNamespace setVariable ["WaldoEcoCommand_LocalIdentityUnitEH", _eventId];

[] call Waldo_fnc_EcoCommand_requestLocalGroundCommandIdentityRefresh;

true
