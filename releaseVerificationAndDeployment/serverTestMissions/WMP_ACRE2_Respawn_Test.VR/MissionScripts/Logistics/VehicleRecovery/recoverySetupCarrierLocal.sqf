/*
 * Author: WaldoTheWarfighter
 * Installs repeat-safe Load and Unload Recovery Package controls on one registered carrier. ACE
 * object interactions are primary when ACE Interact exists; vanilla addActions are the no-ACE
 * fallback. Both modes call the same server-authoritative recovery request and use the combined
 * physical, attached and virtual package count.
 *
 * Locality and repeat/JIP behaviour:
 * Runs on every interface client through object-keyed JIP replay from RecoveryRegisterCarrier.
 * Old ACE paths and vanilla IDs are removed before reinstalling.
 *
 * Arguments: 0: carrier <OBJECT>.
 * Return Value: Boolean - true when the expected local controls were installed.
 * Current caller: Waldo_fnc_RecoveryRegisterCarrier.
 *
 * Example: [_carrier] call Waldo_fnc_RecoverySetupCarrierLocal;
 * Result: the carrier receives Load and Unload actions in ACE, or vanilla fallbacks without ACE.
 */
params [["_target", objNull, [objNull]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {isNull _target}) exitWith {false};

{_target removeAction _x} forEach (_target getVariable ["Waldo_Recovery_CarrierActionIds", []]);
_target setVariable ["Waldo_Recovery_CarrierActionIds", []];
if !(isNil "ace_interact_menu_fnc_removeActionFromObject") then {
    [_target, 0, ["ACE_MainActions", "Waldo_Recovery_Carrier"]] call ace_interact_menu_fnc_removeActionFromObject;
};

private _loadCondition = {
    params ["_target", "_player"];
    private _packageCount = count (getVehicleCargo _target)
        + count (_target getVariable ["Waldo_Recovery_AttachedPackages", []])
        + count (_target getVariable ["Waldo_Recovery_VirtualPackages", []]);
    _target getVariable ["Waldo_Recovery_Carrier", false]
    && {_player distance _target <= ((_target getVariable ["Waldo_Recovery_CarrierRange", 10]) max 3)}
    && {alive _target}
    && {abs speed _target < 1}
    && {_packageCount < (_target getVariable ["Waldo_Recovery_CarrierCapacity", 1])}
};
private _unloadCondition = {
    params ["_target", "_player"];
    private _packageCount = count (getVehicleCargo _target)
        + count (_target getVariable ["Waldo_Recovery_AttachedPackages", []])
        + count (_target getVariable ["Waldo_Recovery_VirtualPackages", []]);
    _target getVariable ["Waldo_Recovery_Carrier", false]
    && {_player distance _target <= ((_target getVariable ["Waldo_Recovery_CarrierRange", 10]) max 3)}
    && {alive _target}
    && {abs speed _target < 1}
    && {_packageCount > 0}
};
private _aceReady = !(isNil "ace_interact_menu_fnc_createAction")
    && {!(isNil "ace_interact_menu_fnc_addActionToObject")};
if (_aceReady) then {
    private _root = ["Waldo_Recovery_Carrier", "Vehicle Recovery", "\A3\ui_f\data\igui\cfg\actions\repair_ca.paa", {}, {true}] call ace_interact_menu_fnc_createAction;
    [_target, 0, ["ACE_MainActions"], _root] call ace_interact_menu_fnc_addActionToObject;
    private _load = ["Waldo_Recovery_Load", "Load Recovery Package", "\A3\ui_f\data\igui\cfg\actions\repair_ca.paa",
        {params ["_target", "_player"]; [_player, "LOAD", _target] remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2];},
        _loadCondition] call ace_interact_menu_fnc_createAction;
    private _unload = ["Waldo_Recovery_Unload", "Unload Recovery Package", "\A3\ui_f\data\igui\cfg\actions\repair_ca.paa",
        {params ["_target", "_player"]; [_player, "UNLOAD", _target] remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2];},
        _unloadCondition] call ace_interact_menu_fnc_createAction;
    [_target, 0, ["ACE_MainActions", "Waldo_Recovery_Carrier"], _load] call ace_interact_menu_fnc_addActionToObject;
    [_target, 0, ["ACE_MainActions", "Waldo_Recovery_Carrier"], _unload] call ace_interact_menu_fnc_addActionToObject;
    _target setVariable ["Waldo_Recovery_CarrierACEActionsInstalled", true];
    _target setVariable ["Waldo_Recovery_CarrierVanillaActionsInstalled", false];
} else {
    private _load = _target addAction ["<t color='#F4C542'>Load Recovery Package</t>", {params ["_target", "_actor"]; [_actor, "LOAD", _target] remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2];}, [], 1.4, true, true, "", "_this distance _target <= ((_target getVariable ['Waldo_Recovery_CarrierRange', 10]) max 3) && {alive _target} && {abs speed _target < 1} && {(count (getVehicleCargo _target)) + (count (_target getVariable ['Waldo_Recovery_AttachedPackages', []])) + (count (_target getVariable ['Waldo_Recovery_VirtualPackages', []])) < (_target getVariable ['Waldo_Recovery_CarrierCapacity', 1])}", 30];
    private _unload = _target addAction ["<t color='#F4C542'>Unload Recovery Package</t>", {params ["_target", "_actor"]; [_actor, "UNLOAD", _target] remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2];}, [], 1.4, true, true, "", "_this distance _target <= ((_target getVariable ['Waldo_Recovery_CarrierRange', 10]) max 3) && {alive _target} && {abs speed _target < 1} && {(count (getVehicleCargo _target)) + (count (_target getVariable ['Waldo_Recovery_AttachedPackages', []])) + (count (_target getVariable ['Waldo_Recovery_VirtualPackages', []])) > 0}", 30];
    _target setVariable ["Waldo_Recovery_CarrierActionIds", [_load, _unload]];
    _target setVariable ["Waldo_Recovery_CarrierACEActionsInstalled", false];
    _target setVariable ["Waldo_Recovery_CarrierVanillaActionsInstalled", true];
};
_target setVariable ["Waldo_Recovery_CarrierActionsInstalled", true];
diag_log format ["[WMP RECOVERY] Carrier interactions installed object=%1 mode=%2 owner=%3.", netId _target, ["VANILLA", "ACE"] select _aceReady, clientOwner];
true
