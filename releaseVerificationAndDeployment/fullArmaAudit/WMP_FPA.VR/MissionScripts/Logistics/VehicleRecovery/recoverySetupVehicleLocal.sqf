/*
 * Author: WaldoTheWarfighter
 * Installs the repeat-safe local packaging interaction for one registered recovery vehicle. ACE
 * Interact is the primary control when available; a vanilla addAction is installed only when ACE
 * Interact is absent. Both paths call the same server-authoritative PACK operation. An optional
 * shared preparation procedure changes what happens after selecting the action, not whether the
 * action exists.
 *
 * Locality and repeat/JIP behaviour:
 * Runs on every interface client through object-keyed JIP replay from RecoveryRegisterVehicle.
 * Existing ACE paths and vanilla action IDs are removed before reinstalling, so runtime ZEN
 * registration, JIP and reconfiguration cannot duplicate controls.
 *
 * Arguments:
 * 0: recoverable vehicle <OBJECT>.
 * 1: procedure settings <ARRAY> - [] or [challengeId, difficulty] (default []).
 * Return Value: Boolean - true when the expected local interaction was installed.
 * Current caller: Waldo_fnc_RecoveryRegisterVehicle.
 *
 * Example: [_vehicle, []] call Waldo_fnc_RecoverySetupVehicleLocal;
 * Result: the vehicle receives one Package for Recovery ACE action, or one vanilla fallback.
 */

params [["_target", objNull, [objNull]], ["_interactionSettings", [], [[]]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {isNull _target}) exitWith {false};

if (count _interactionSettings >= 2) then {
    [_target, _interactionSettings] call Waldo_fnc_RecoveryInteractionSetup;
};

{_target removeAction _x} forEach (_target getVariable ["Waldo_Recovery_VehicleActionIds", []]);
_target setVariable ["Waldo_Recovery_VehicleActionIds", []];
if !(isNil "ace_interact_menu_fnc_removeActionFromObject") then {
    [_target, 0, ["ACE_MainActions", "Waldo_Recovery_Package"]] call ace_interact_menu_fnc_removeActionFromObject;
};

private _condition = {
    params ["_target", "_player"];
    private _config = _target getVariable ["Waldo_Recovery_Config", ["MAIN", 0.55, true, false, "", true, 1]];
    _target getVariable ["Waldo_Recovery_Registered", false]
    && {_player distance _target < 5}
    && {vehicle _player == _player}
    // Destroyed vehicle wrecks often retain dead crew proxies. They are not occupants and must not
    // make a wreck registered through Zeus permanently fail its packaging condition.
    && {{alive _x} count crew _target == 0}
    && {abs speed _target < 1}
    && {(damage _target >= (_config select 1)) || {!alive _target}}
    && {!(_config select 3) || {_player getUnitTrait "engineer"}}
};
private _statement = {
    params ["_target", "_player"];
    if (_target getVariable ["Waldo_Recovery_InteractionEnabled", false]) then {
        _target call Waldo_fnc_MiniGameInteractionActivate;
    } else {
        [_player, "PACK", _target] remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2];
    };
};

private _aceReady = !(isNil "ace_interact_menu_fnc_createAction")
    && {!(isNil "ace_interact_menu_fnc_addActionToObject")};
if (_aceReady) then {
    private _action = [
        "Waldo_Recovery_Package", "Package for Recovery",
        "\A3\ui_f\data\igui\cfg\actions\repair_ca.paa", _statement, _condition
    ] call ace_interact_menu_fnc_createAction;
    [_target, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
    _target setVariable ["Waldo_Recovery_VehicleACEActionsInstalled", true];
    _target setVariable ["Waldo_Recovery_VehicleVanillaActionsInstalled", false];
} else {
    private _id = _target addAction [
        "<t color='#F4C542'>Package for Recovery</t>",
        {params ["_target", "_actor", "_arguments"]; [_target, _actor] call (_arguments select 0);},
        [_statement], 1.5, true, true, "",
        "[_target, _this] call (_target getVariable ['Waldo_Recovery_PackageCondition', {false}])", 5
    ];
    _target setVariable ["Waldo_Recovery_PackageCondition", _condition];
    _target setVariable ["Waldo_Recovery_VehicleActionIds", [_id]];
    _target setVariable ["Waldo_Recovery_VehicleACEActionsInstalled", false];
    _target setVariable ["Waldo_Recovery_VehicleVanillaActionsInstalled", true];
};
_target setVariable ["Waldo_Recovery_VehicleActionInstalled", true];
private _livingCrew = {alive _x} count crew _target;
private _eligibleNow = [_target, player] call _condition;
_target setVariable ["Waldo_Recovery_LastLocalActionCheck", [diag_tickTime, clientOwner, ["VANILLA", "ACE"] select _aceReady, _eligibleNow, alive _target, count crew _target, _livingCrew]];
diag_log format ["[WMP RECOVERY] Vehicle interaction installed object=%1 mode=%2 procedure=%3 clientOwner=%4 eligibleNow=%5 alive=%6 crewTotal=%7 crewLiving=%8 registered=%9.", netId _target, ["VANILLA", "ACE"] select _aceReady, count _interactionSettings >= 2, clientOwner, _eligibleNow, alive _target, count crew _target, _livingCrew, _target getVariable ["Waldo_Recovery_Registered", false]];
true
