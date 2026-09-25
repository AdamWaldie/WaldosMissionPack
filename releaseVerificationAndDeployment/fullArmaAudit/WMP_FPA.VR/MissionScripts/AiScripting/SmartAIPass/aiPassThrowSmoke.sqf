/*
 * Author: WaldoTheWarfighter
 * Makes one soldier throw a smoke grenade he is carrying, facing a given direction.
 *
 * Smoke magazines are identified from config (ammo simulation shotSmoke or shotSmokeX), as Smart
 * Combat V2 did, so mod smoke works. The throw muzzle is the "Throw" weapon muzzle that accepts that
 * magazine. Engine AI already treat smoke particles as blocking sight.
 * Locality and authority: call where the unit is local (forceWeaponFire is local-argument).
 *
 * Arguments:
 * 0: unit <OBJECT>
 * 1: towards <ARRAY> - ATL position to throw towards
 *
 * Return Value:
 * Boolean - true when a smoke grenade was thrown
 *
 * Example:
 * [_unit, _enemyPos] call Waldo_fnc_AIPassThrowSmoke;
 * Result: the unit screens a street crossing.
 *
 * Current callers: Waldo_fnc_AIPassFlankStep.
 */

params [["_unit", objNull, [objNull]], ["_towards", [], [[]]]];
if (isNull _unit || {!alive _unit} || {!local _unit} || {vehicle _unit != _unit}) exitWith {false};
private _throwConfig = configFile >> "CfgWeapons" >> "Throw";
private _thrown = false;
{
    private _magazine = _x;
    private _ammo = getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
    if (getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") in ["shotSmoke", "shotSmokeX"]) then {
        private _muzzles = getArray (_throwConfig >> "muzzles");
        private _muzzleIndex = _muzzles findIf {_magazine in getArray (_throwConfig >> _x >> "magazines")};
        if (_muzzleIndex >= 0) then {
            private _muzzle = _muzzles select _muzzleIndex;
            if (count _towards >= 2) then {_unit doWatch _towards};
            _unit forceWeaponFire [_muzzle, _muzzle];
            _thrown = true;
        };
    };
    if (_thrown) exitWith {};
} forEach (magazines _unit);
_thrown
