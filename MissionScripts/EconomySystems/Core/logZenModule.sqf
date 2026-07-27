/* Records every Economy ZEN module invocation before its guard or handler runs. */
params [["_moduleName", "UNKNOWN", [""]], ["_payload", [], [[]]]];
private _record = [serverTime, _moduleName, name player, clientOwner, _payload, [] call Waldo_fnc_EcoCore_isActive];
missionNamespace setVariable ["WaldoEcoCore_LastZenInvocation", _record];
diag_log format ["[WMP ECO ZEN] invoked module=%1 curator=%2 clientOwner=%3 active=%4 payload=%5", _moduleName, name player, clientOwner, _record select 5, _payload];
true
