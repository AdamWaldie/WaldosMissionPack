/*
 * Author: WaldoTheWarfighter
 * Registers any vehicle as a recovery-package carrier with physical or virtual cargo handling.
 *
 * Automatic mode uses Arma vehicle-in-vehicle cargo only when the package fits the carrier's
 * configured cargo bay, then falls back to a server-owned virtual manifest. Virtual mode works on
 * vehicle classes without an engine cargo bay. Physical mode deliberately requires that bay.
 * Registration is repeat-safe and its public settings support local actions and JIP. Eden object
 * init fields execute on every machine, so non-server copies are ignored; ZEN sends live requests
 * through the validated server runtime bridge.
 *
 * Locality and authority:
 * Server-owned carrier/manifest registration. Eden client copies exit; local actions are installed
 * from published object state for current/JIP clients and every load/unload mutation returns to server.
 *
 * Arguments:
 * 0: carrier <OBJECT>
 * 1: loading range <NUMBER> (default 10)
 * 2: cargo mode <STRING> - "AUTO", "VIRTUAL" or "PHYSICAL" (default "AUTO")
 * 3: package capacity <NUMBER> (default 1)
 * 4: attached-deck offset <ARRAY> - model-space [left/right, forward/back, height], or [] to disable
 * 5: attached-deck direction <NUMBER> - package direction relative to carrier (default 0)
 *
 * Return Value:
 * Boolean - true when registered (or when a duplicate non-server Eden copy was ignored); otherwise false.
 *
 * Example:
 * [this, 10, "AUTO", 2, [0, -1.3, 1.25], 0] call Waldo_fnc_RecoveryRegisterCarrier;
 * Result: this carrier accepts up to two packages using its deck offset or safe automatic fallback.
 *
 * Current callers: Vehicle Recovery ZEN carrier module, restored-carrier replay and mission setup.
 */

params [
    ["_carrier", objNull, [objNull]],
    ["_range", 10, [0]],
    ["_mode", "AUTO", [""]],
    ["_capacity", 1, [0]],
    ["_deckOffset", [], [[]]],
    ["_deckDirection", 0, [0]]
];
if (isNull _carrier || {!(_carrier isKindOf "AllVehicles")} || {_carrier isKindOf "CAManBase"}) exitWith {false};
if (!isServer) exitWith {true};
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
if (count _deckOffset != 3) then {_deckOffset = []};
_carrier setVariable ["Waldo_Recovery_CarrierDeckOffset", _deckOffset, true];
_carrier setVariable ["Waldo_Recovery_CarrierDeckDirection", _deckDirection, true];
private _attachedPackages = (_carrier getVariable ["Waldo_Recovery_AttachedPackages", []]) select {!isNull _x};
_carrier setVariable ["Waldo_Recovery_AttachedPackages", _attachedPackages, true];
private _virtualPackages = (_carrier getVariable ["Waldo_Recovery_VirtualPackages", []]) select {!isNull _x};
_carrier setVariable ["Waldo_Recovery_VirtualPackages", _virtualPackages, true];
[_carrier] remoteExecCall ["Waldo_fnc_RecoverySetupCarrierLocal", 0, _carrier];
diag_log format ["[WMP RECOVERY] Carrier registered object=%1 class=%2 range=%3 mode=%4 capacity=%5 deckOffset=%6 owner=%7.", netId _carrier, typeOf _carrier, _range max 3, _mode, (round _capacity) max 1, _deckOffset, owner _carrier];
true
