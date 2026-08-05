/*
 * Author: WaldoTheWarfighter, Val
 * Installs repeat-safe Hazard Equipment interactions. A dosimeter can read self or another player's
 * client-owned exposure without continuous broadcasts. Configured treatment items create self and
 * target actions with an ACE progress bar; the giver's item is consumed only on completion. A
 * vanilla self-read fallback is provided when ACE Interact is unavailable.
 * Locality and authority: interface-client actions only; exposure changes occur on the patient owner.
 *
 * Arguments: None.
 * Return Value: Boolean - true when installed or already present on this client.
 *
 * Example:
 * [] call Waldo_fnc_HazardInteractionInit;
 * Result: installs local Hazard Equipment actions according to environmentConfig.sqf.
 * Current caller: Waldo_fnc_HazardInit before starting the local evaluator.
 */

if (!hasInterface || {isNull player}) exitWith {false};
if (missionNamespace getVariable ["Waldo_Hazard_InteractionsInstalled", false]) exitWith {true};
missionNamespace setVariable ["Waldo_Hazard_InteractionsInstalled", true];
private _aceReady = !(isNil "ace_interact_menu_fnc_createAction") && {!(isNil "ace_interact_menu_fnc_addActionToClass")};
if (!_aceReady) exitWith {
    private _id = player addAction ["<t color='#79C7FF'>Hazard Equipment: Read Exposure</t>", {[player, player] call Waldo_fnc_HazardReadExposureLocal}, [], -85, false, true, "", "alive _target && {_this isEqualTo _target}"];
    player setVariable ["Waldo_Hazard_FallbackReadAction", _id];
    true
};

private _canRead = {
    if !(missionNamespace getVariable ["Waldo_Hazard_DosimeterEnable", true]) exitWith {false};
    if !(missionNamespace getVariable ["Waldo_Hazard_DosimeterRequireItem", false]) exitWith {true};
    private _items = missionNamespace getVariable ["Waldo_Hazard_DosimeterItems", []];
    _items findIf {_x in (items _player + assignedItems _player)} >= 0
};
private _selfRoot = ["Waldo_HazardEquipment_Self", "Hazard Equipment", "\a3\ui_f\data\igui\cfg\holdactions\holdaction_revive_ca.paa", {}, {true}] call ace_interact_menu_fnc_createAction;
["CAManBase", 1, ["ACE_SelfActions"], _selfRoot, true] call ace_interact_menu_fnc_addActionToClass;
private _selfRead = ["Waldo_Hazard_ReadSelf", "Read Exposure", "\a3\ui_f\data\igui\cfg\holdactions\holdaction_revive_ca.paa", {[_player, _player] call Waldo_fnc_HazardReadExposureLocal}, _canRead] call ace_interact_menu_fnc_createAction;
["CAManBase", 1, ["ACE_SelfActions", "Waldo_HazardEquipment_Self"], _selfRead, true] call ace_interact_menu_fnc_addActionToClass;

private _targetRoot = ["Waldo_HazardEquipment_Target", "Hazard Equipment", "\a3\ui_f\data\igui\cfg\holdactions\holdaction_revive_ca.paa", {}, {_target != _player && {alive _target}}] call ace_interact_menu_fnc_createAction;
["CAManBase", 0, ["ACE_MainActions"], _targetRoot, true] call ace_interact_menu_fnc_addActionToClass;
private _otherRead = ["Waldo_Hazard_ReadOther", "Read Exposure", "\a3\ui_f\data\igui\cfg\holdactions\holdaction_revive_ca.paa", {[_target, _player] call Waldo_fnc_HazardReadExposureLocal}, _canRead] call ace_interact_menu_fnc_createAction;
["CAManBase", 0, ["ACE_MainActions", "Waldo_HazardEquipment_Target"], _otherRead, true] call ace_interact_menu_fnc_addActionToClass;

private _treatmentCondition = {
    private _rows = missionNamespace getVariable ["Waldo_Hazard_Treatments", []];
    private _hasItem = _rows findIf {(_x param [0, ""]) in items _player} >= 0;
    private _qualified = !(missionNamespace getVariable ["Waldo_Hazard_TreatmentMedicOnly", false]) || {_player getUnitTrait "Medic"};
    _hasItem && _qualified
};
private _treatmentStatement = {
    params ["_target", "_player"];
    private _rows = missionNamespace getVariable ["Waldo_Hazard_Treatments", []];
    private _index = _rows findIf {(_x param [0, ""]) in items _player};
    if (_index < 0) exitWith {};
    private _row = _rows select _index;
    _row params ["_itemClass", ["_label", "Hazard treatment"], ["_reduction", 2]];
    private _duration = (missionNamespace getVariable ["Waldo_Hazard_TreatmentDuration", 4]) max 0;
    [_duration, [_target, _player, _itemClass, _label, _reduction], {
        params ["_args"];
        _args params ["_target", "_player", "_itemClass", "_label", "_reduction"];
        if !(_itemClass in items _player) exitWith {};
        _player removeItem _itemClass;
        [_target, _player, _reduction, _label] remoteExecCall ["Waldo_fnc_HazardApplyTreatmentLocal", owner _target];
    }, {}, format ["Administering %1", _label], {
        params ["_args"];
        _args params ["_target", "_player"];
        alive _target && {alive _player} && {_target distance _player <= 3}
    }] call ace_common_fnc_progressBar;
};
private _selfTreat = ["Waldo_Hazard_TreatSelf", "Administer Hazard Treatment", "\a3\ui_f\data\igui\cfg\holdactions\holdaction_revive_ca.paa", _treatmentStatement, _treatmentCondition] call ace_interact_menu_fnc_createAction;
["CAManBase", 1, ["ACE_SelfActions", "Waldo_HazardEquipment_Self"], _selfTreat, true] call ace_interact_menu_fnc_addActionToClass;
private _otherTreat = ["Waldo_Hazard_TreatOther", "Administer Hazard Treatment", "\a3\ui_f\data\igui\cfg\holdactions\holdaction_revive_ca.paa", _treatmentStatement, _treatmentCondition] call ace_interact_menu_fnc_createAction;
["CAManBase", 0, ["ACE_MainActions", "Waldo_HazardEquipment_Target"], _otherTreat, true] call ace_interact_menu_fnc_addActionToClass;
true
