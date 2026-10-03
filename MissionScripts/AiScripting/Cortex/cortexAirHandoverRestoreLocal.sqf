/*
 * Author: WaldoTheWarfighter
 * Restores the pilot AI features temporarily leased while a direct Zeus aircraft order takes over
 * from a finite Cortex attack. The token prevents an older delayed restore from altering a newer
 * handover, and only features observed enabled at lease start are restored. Gunners are untouched.
 * Locality/authority: current aircraft owner. A local caller, the server, or the owner recorded when
 * the lease began may request restoration after locality migration.
 * Repeat/JIP: token guarded and repeat safe. The short lease is transient and is never replayed to
 * JIP clients; its public token exists only so a new owner can validate and finish restoration.
 * Arguments: 0: aircraft <OBJECT>; 1: leased pilot <OBJECT>; 2: lease token <STRING>;
 * 3: originally enabled AI feature names <ARRAY>, default []; 4: original pilot combat mode
 * <STRING>, default "YELLOW"; 5: original group combat mode <STRING>, default "YELLOW";
 * 6: original autonomous attack permission <BOOL>, default true; 7: leased pilot combat behaviour
 * <STRING>, default ""; 8: original pilot combat behaviour <STRING>, default "". The
 * curator-authored group behaviour is deliberately retained.
 * Return Value: BOOL true when the current lease was restored, otherwise false.
 * Current callers: delayed Zeus-handover cleanup in Waldo_fnc_CortexAirAttack.
 * Example: [_heli,driver _heli,"heli:2:10.5",[],"RED","RED",true,"AWARE","COMBAT"]
 *     call Waldo_fnc_CortexAirHandoverRestoreLocal;
 */
params [
    ["_aircraft",objNull,[objNull]],
    ["_pilot",objNull,[objNull]],
    ["_token","",[""]],
    ["_features",[],[[]]],
    ["_previousCombatMode","YELLOW",[""]],
    ["_previousGroupCombatMode","YELLOW",[""]],
    ["_previousAttackEnabled",true,[true]],
    ["_leasedPilotBehaviour","",[""]],
    ["_previousPilotBehaviour","",[""]]
];
if (isNull _aircraft || {!local _aircraft} || {_token == ""}) exitWith {false};
private _lease=_aircraft getVariable ["Waldo_Cortex_AirHandoverLease",[]];
if (count _lease != 2 || {(_lease select 0) != _token}) exitWith {false};
private _originOwner=_lease select 1;
if (remoteExecutedOwner > 0
    && {remoteExecutedOwner != 2}
    && {remoteExecutedOwner != _originOwner}) exitWith {false};
if (!isNull _pilot && {alive _pilot} && {local _pilot}) then {
    {_pilot enableAI _x} forEach (_features arrayIntersect ["AUTOCOMBAT","TARGET","AUTOTARGET"]);
    if (unitCombatMode _pilot == "BLUE") then {_pilot setUnitCombatMode _previousCombatMode};
    // Undo only the pilot behaviour still owned by this bounded handover lease. A later
    // curator/script change is authoritative and must never be overwritten by cleanup.
    if (_leasedPilotBehaviour != "" && {_previousPilotBehaviour != ""}
        && {combatBehaviour _pilot == _leasedPilotBehaviour}) then {
        _pilot setCombatBehaviour _previousPilotBehaviour;
    };
};
private _group=group _pilot;
if (!isNull _group && {local _group} && {combatMode _group == "YELLOW"}) then {
    _group setCombatMode _previousGroupCombatMode;
};
if (!isNull _group && {local _group} && {!attackEnabled _group}) then {
    _group enableAttack _previousAttackEnabled;
};
_aircraft setVariable ["Waldo_Cortex_AirHandoverLease",nil,true];
true
