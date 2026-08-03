/*
 * Author: WaldoTheWarfighter
 * Registers any vehicle as a recovery-package carrier with physical or virtual cargo handling.
 *
 * Automatic mode uses Arma vehicle-in-vehicle cargo only when the package fits the carrier's
 * configured cargo bay, then falls back to a server-owned virtual manifest. Virtual mode works on
 * vehicle classes without an engine cargo bay. Physical mode deliberately requires that bay.
 * Registration is repeat-safe and its public settings support local actions and JIP.
 *
 * Arguments:
 * 0: carrier <OBJECT>
 * 1: loading range <NUMBER> (default 10)
 * 2: cargo mode <STRING> - "AUTO", "VIRTUAL" or "PHYSICAL" (default "AUTO")
 * 3: package capacity <NUMBER> (default 1)
 *
 * Return Value:
 * Boolean - true when forwarded or registered; false when invalid or unauthorized.
 *
 * Example:
 * [this, 10, "AUTO", 2] call Waldo_fnc_RecoveryRegisterCarrier;
 *
 * Current callers: Vehicle Recovery ZEN carrier module, restored-carrier replay and mission setup.
 */

params [
    ["_carrier", objNull, [objNull]],
    ["_range", 10, [0]],
    ["_mode", "AUTO", [""]],
    ["_capacity", 1, [0]]
];
if (isNull _carrier || {!(_carrier isKindOf "AllVehicles")} || {_carrier isKindOf "CAManBase"}) exitWith {false};
if (!isServer) exitWith {[_carrier, _range, _mode, _capacity] remoteExecCall ["Waldo_fnc_RecoveryRegisterCarrier", 2]; true};
private _authorized = true;
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    _authorized = !isNull _caller && {!isNull getAssignedCuratorLogic _caller};
};
if (!_authorized) exitWith {false};
_mode = toUpperANSI _mode;
if !(_mode in ["AUTO", "VIRTUAL", "PHYSICAL"]) then {_mode = "AUTO"};
_carrier setVariable ["Waldo_Recovery_Carrier", true, true];
_carrier setVariable ["Waldo_Recovery_CarrierRange", _range max 3, true];
_carrier setVariable ["Waldo_Recovery_CarrierMode", _mode, true];
_carrier setVariable ["Waldo_Recovery_CarrierCapacity", (round _capacity) max 1, true];
private _virtualPackages = (_carrier getVariable ["Waldo_Recovery_VirtualPackages", []]) select {!isNull _x};
_carrier setVariable ["Waldo_Recovery_VirtualPackages", _virtualPackages, true];
[_carrier] remoteExecCall ["Waldo_fnc_RecoverySetupCarrierLocal", 0, _carrier];
true
