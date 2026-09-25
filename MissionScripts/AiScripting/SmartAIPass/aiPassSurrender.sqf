/*
 * Author: WaldoTheWarfighter
 * Makes the survivors of a broken squad surrender.
 *
 * Each local survivor drops his weapons into a ground weapon holder at his feet (attachments and
 * loaded magazines kept), then surrenders through ACE Captives when it is loaded, so players can
 * take him prisoner, or through vanilla setCaptive and the surrender animation otherwise. Surrendered
 * units are excluded from every further WMP AI change (Waldo_AI_Exclude and Waldo_AIPass_Exclude).
 * Only reached when Waldo_AIPass_Surrender_Enable is true.
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
 * [_group] call Waldo_fnc_AIPassSurrender;
 * Result: the last two defenders throw down their rifles and raise their hands.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]]];
private _surrendered = 0;
private _aceCaptives = !isNil "ace_captives_fnc_setSurrendered";
{
    private _unit = _x;
    if (alive _unit && {local _unit} && {vehicle _unit == _unit}) then {
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
diag_log format ["[WMP AI PASS] %1 surrendered (%2 units)", _group, _surrendered];
_surrendered
