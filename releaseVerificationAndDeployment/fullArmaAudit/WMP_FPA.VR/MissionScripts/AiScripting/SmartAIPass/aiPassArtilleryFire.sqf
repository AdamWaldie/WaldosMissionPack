/*
 * Author: WaldoTheWarfighter
 * Fires one artillery mission from a local battery, with range-scaled dispersion, and optionally
 * moves the battery afterwards (shoot and scoot).
 *
 * HE mode uses the battery's most destructive non-smoke artillery ammunition (highest CfgAmmo hit),
 * so smoke is not used by accident; SMOKE mode uses a smoke magazine (smoke simulation, or "smoke" in
 * the ammo or magazine name) and fires two rounds, or does nothing if the battery has none. The aim point is displaced by the target's
 * position error plus 1% of the range (capped at 150 m), from Digii. A mission that the engine
 * reports as unreachable (getArtilleryETA below 0) is not fired. The battery is busy until its rounds
 * have landed. With Waldo_AIPass_Artillery_ShootAndScoot, a mobile battery drives 200-350 m to a new
 * position once the mission is complete, through an inserted waypoint.
 * Locality and authority: call where the artillery vehicle is local.
 *
 * Arguments:
 * 0: battery <OBJECT> - artillery vehicle or static weapon
 * 1: target <ARRAY> - ATL position
 * 2: error <NUMBER> - estimated position error in metres (optional, default: 0)
 * 3: mode <STRING> - "HE" or "SMOKE" (optional, default: "HE")
 *
 * Return Value:
 * Boolean - true when the mission was fired
 *
 * Example:
 * [_mortar, _enemyPos, 25] call Waldo_fnc_AIPassArtilleryFire;
 * Result: three rounds land around the enemy position.
 *
 * Current callers: Waldo_fnc_AIPassArtilleryRequest and the counter-battery handler.
 */

params [["_battery", objNull, [objNull]], ["_target", [], [[]]], ["_error", 0, [0]], ["_mode", "HE", [""]]];
if (isNull _battery || {!alive _battery} || {!local _battery} || {!alive gunner _battery} || {count _target < 2}) exitWith {false};
private _smoke = toUpperANSI _mode == "SMOKE";
private _best = "";
private _bestHit = -1;
{
    private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
    private _isSmoke = getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") in ["shotSmoke", "shotSmokeX"]
        || {(toLowerANSI _ammo) find "smoke" >= 0} || {(toLowerANSI _x) find "smoke" >= 0};
    private _hit = getNumber (configFile >> "CfgAmmo" >> _ammo >> "hit");
    if (_isSmoke == _smoke && {_smoke || {_hit > _bestHit}}) then {_best = _x; _bestHit = _hit};
} forEach (getArtilleryAmmo [_battery]);
if (_best == "") exitWith {false};
private _dispersion = _error + (((_battery distance2D _target) * 0.01) min 150);
private _aim = _target getPos [random _dispersion, random 360];
if !(_aim inRangeOfArtillery [[_battery], _best]) exitWith {false};
private _eta = _battery getArtilleryETA [_aim, _best];
if (_eta < 0) exitWith {false};
private _rounds = [(missionNamespace getVariable ["Waldo_AIPass_Artillery_Rounds", 3]) max 1, 2] select _smoke;
_battery doArtilleryFire [_aim, _best, _rounds];
_battery setVariable ["Waldo_AIPass_BusyUntil", time + _eta + _rounds * 6 + 20];
missionNamespace setVariable ["Waldo_AIPass_ArtilleryMissions", (missionNamespace getVariable ["Waldo_AIPass_ArtilleryMissions", 0]) + 1];
diag_log format ["[WMP AI PASS] Artillery %1 fired %2 x %3 at %4 (eta %5 s)", typeOf _battery, _rounds, _best, _aim, round _eta];
if ((missionNamespace getVariable ["Waldo_AIPass_Artillery_ShootAndScoot", true]) && {!(_battery isKindOf "StaticWeapon")}) then {
    [{
        params ["_job"];
        private _battery = _job get "battery";
        if (alive _battery && {local _battery} && {canMove _battery} && {!isNull driver _battery}) then {
            private _group = group driver _battery;
            private _spot = (getPosATL _battery) getPos [200 + random 150, random 360];
            if (!surfaceIsWater _spot && {local _group}) then {[_group, _spot, 30] call Waldo_fnc_AIPassGroupMove};
        };
        -1
    }, createHashMapFromArray [["battery", _battery]], _eta + _rounds * 5 + 10] call Waldo_fnc_AIPassQueueJob;
};
true
