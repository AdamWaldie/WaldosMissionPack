/*
 * Author: WaldoTheWarfighter
 * Makes the survivors of a broken squad surrender.
 *
 * Each local survivor drops his weapons into a ground weapon holder at his feet (attachments and
 * loaded magazines kept), then surrenders through ACE Captives when it is loaded, so players can
 * take him prisoner, or through vanilla setCaptive and the surrender animation otherwise. Surrendered
 * units are excluded from every further WMP AI change (Waldo_AI_Exclude and Waldo_AIPass_Exclude).
 * Rechecks surrender permission and releases Cortex orders before handing control to captives.
 * Repeat/JIP: excluded surrendering units are not processed twice; physical state is engine replicated.
 * Locality and authority: call where the group is local; exclusion flags are broadcast once per unit
 * so every machine skips them.
 *
 * Arguments:
 * 0: group <GROUP>
 *
 * Return Value:
 * Number - units that surrendered
 *
 * Example:
 * [_group] call Waldo_fnc_CortexSurrender;
 * Result: the last two defenders throw down their rifles and raise their hands.
 *
 * Current caller: Waldo_fnc_CortexGroupTick.
 */

params [["_group", grpNull, [grpNull]]];
if (isNull _group || {!local _group}
    || {!([_group] call Waldo_fnc_CortexIsEligible)}
    || {!([_group,"Waldo_AIPass_Surrender_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}) exitWith {0};
if ((units _group) findIf {local _x && {vehicle _x == _x} && {[_x] call Waldo_fnc_CortexCombatEffective}} < 0) exitWith {0};
// Release movement and stance ownership before ACE starts its surrender state.
// Otherwise the next ineligible-group cleanup can overwrite the captive's posture.
if ((_group getVariable ["Waldo_AIPass_Garrison",[]]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexGarrisonRelease};
if ((_group getVariable ["Waldo_AIPass_Defend",[]]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexDefendRelease};
if (_group getVariable ["Waldo_AIPass_ClearBuilding",false]) then {[_group] call Waldo_fnc_CortexClearRelease};
[_group,false,"SURRENDER"] call Waldo_fnc_CortexReleaseGroup;
private _surrendered = 0;
private _aceCaptives = !isNil "ace_captives_fnc_setSurrendered";
{
    private _unit = _x;
    if ([_unit] call Waldo_fnc_CortexCombatEffective && {local _unit} && {vehicle _unit == _unit}) then {
        private _loadout = getUnitLoadout _unit;
        private _holder = createVehicle ["GroundWeaponHolder", getPosATL _unit, [], 0.5, "CAN_COLLIDE"];
        {
            private _weapon = _loadout select _x;
            if (_weapon isNotEqualTo []) then {_holder addWeaponWithAttachmentsCargoGlobal [_weapon, 1]};
        } forEach [0, 1, 2];
        {_unit removeWeaponGlobal _x} forEach ([primaryWeapon _unit, secondaryWeapon _unit, handgunWeapon _unit] select {_x != ""});
        _unit setVariable ["Waldo_AIPass_Exclude", true, true];
        _unit setVariable ["Waldo_AI_Exclude", true, true];
        if (_aceCaptives) then {
            [_unit, true] call ace_captives_fnc_setSurrendered;
        } else {
            _unit setCaptive true;
            _unit action ["Surrender", _unit];
        };
        _surrendered = _surrendered + 1;
    };
} forEach (units _group);
missionNamespace setVariable ["Waldo_AIPass_Surrenders", (missionNamespace getVariable ["Waldo_AIPass_Surrenders", 0]) + _surrendered];
diag_log format ["[WMP CORTEX] %1 surrendered (%2 units)", _group, _surrendered];
_surrendered
