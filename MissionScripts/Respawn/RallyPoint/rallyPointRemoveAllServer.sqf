/* Removes every active rally, used by runtime disable and Zeus control. */
if (!isServer) exitWith {[] remoteExecCall ["Waldo_fnc_RallyPointRemoveAllServer", 2]; false};
private _authorized = true;
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    _authorized = !isNull _caller && {!isNull getAssignedCuratorLogic _caller};
};
if (!_authorized) exitWith {false};
{if (_x getVariable ["Waldo_Rally_Active", false]) then {[_x, "Rally-point service was disabled.", "WARNING"] spawn Waldo_fnc_RallyPointRemoveServer}} forEach allGroups;
true
