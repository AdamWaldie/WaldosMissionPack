/*
 * Author: WaldoTheWarfighter
 * Makes one soldier throw a smoke or fragmentation grenade he is carrying, towards a position.
 *
 * Grenade types are identified from config, so mod grenades work: smoke is ammo simulation shotSmoke
 * or shotSmokeX (Smart Combat V2's method); fragmentation is shotGrenade. The throw muzzle is the
 * "Throw" weapon muzzle that accepts that magazine. A fragmentation grenade is never thrown when a
 * friendly or civilian soldier is within 12 m of the target, or when the target is under 8 m or over
 * 40 m away. Engine AI already treat smoke particles as blocking sight.
 * Locality and authority: call where the unit is local (forceWeaponFire is local-argument).
 *
 * Arguments:
 * 0: unit <OBJECT>
 * 1: towards <ARRAY> - ATL position
 * 2: kind <STRING> - "SMOKE" or "FRAG" (optional, default: "SMOKE")
 *
 * Return Value:
 * Boolean - true when a grenade was thrown
 *
 * Example:
 * [_unit, _enemyPos, "FRAG"] call Waldo_fnc_AIPassThrowGrenade;
 * Result: the lead assaulter throws a grenade before the final rush.
 *
 * Current callers: Waldo_fnc_AIPassFlankStep and Waldo_fnc_AIPassRetreat.
 */

params [["_unit", objNull, [objNull]], ["_towards", [], [[]]], ["_kind", "SMOKE", [""]]];
if (isNull _unit || {!alive _unit} || {!local _unit} || {vehicle _unit != _unit} || {count _towards < 2}) exitWith {false};
private _simulations = if (toUpperANSI _kind == "FRAG") then {["shotGrenade"]} else {["shotSmoke", "shotSmokeX"]};
if (toUpperANSI _kind == "FRAG") then {
    private _distance = _unit distance2D _towards;
    private _side = side group _unit;
    if (_distance < 8 || {_distance > 40}) exitWith {_simulations = []};
    if ((_towards nearEntities ["CAManBase", 12]) findIf {
        private _otherSide = side group _x;
        alive _x && {_otherSide == civilian || {_side getFriend _otherSide >= 0.6}}
    } >= 0) then {_simulations = []};
};
if (_simulations isEqualTo []) exitWith {false};
private _throwConfig = configFile >> "CfgWeapons" >> "Throw";
private _muzzles = getArray (_throwConfig >> "muzzles");
private _thrown = false;
{
    private _magazine = _x;
    private _ammo = getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
    if (getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") in _simulations) then {
        private _muzzleIndex = _muzzles findIf {_magazine in getArray (_throwConfig >> _x >> "magazines")};
        if (_muzzleIndex >= 0) then {
            private _muzzle = _muzzles select _muzzleIndex;
            _unit doWatch _towards;
            _unit forceWeaponFire [_muzzle, _muzzle];
            _thrown = true;
        };
    };
    if (_thrown) exitWith {};
} forEach (magazines _unit);
_thrown
