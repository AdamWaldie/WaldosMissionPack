/*
 * Author: WaldoTheWarfighter
 * Fires one artillery mission from a local battery, with range-scaled dispersion, and optionally
 * moves the battery afterwards (shoot and scoot).
 *
 * HE mode uses the battery's most destructive plain shell (highest CfgAmmo hit), never smoke,
 * illumination or submunition rounds such as scatterable mines and cluster; SMOKE mode uses a smoke magazine (smoke simulation, or "smoke" in
 * the ammo or magazine name) and fires two rounds, or does nothing if the battery has none. The aim point is displaced by the target's
 * position error plus 1% of the range (capped at 150 m), from Digii. A mission that the engine
 * reports as unreachable (getArtilleryETA below 0) is not fired. The battery is busy until its rounds
 * have landed. With shoot and scoot on (Waldo_AIPass_Artillery_ShootAndScoot for support,
 * Waldo_AIPass_CounterBattery_ShootAndScoot for counter-battery), a mobile battery drives 200-350 m
 * to a new position once the mission is complete, through an inserted waypoint.
 * Locality and authority: call where the artillery vehicle is local.
 *
 * Review contract: Repeated calls refuse a busy battery. Every shot request checks live role, switch, eligibility and safety at the dispersed aim point; delayed relocation rechecks eligibility.
 *
 * Arguments:
 * 0: battery <OBJECT> - artillery vehicle or static weapon
 * 1: target <ARRAY> - ATL position
 * 2: error <NUMBER> - estimated position error in metres (optional, default: 0)
 * 3: mode <STRING> - "HE" or "SMOKE" (optional, default: "HE")
 * 4: rounds <NUMBER> - HE rounds to fire (optional, default: -1 = Waldo_AIPass_Artillery_Rounds)
 * 5: shoot and scoot <BOOL, NUMBER> (optional, default: -1 = Waldo_AIPass_Artillery_ShootAndScoot)
 *
 * 6: purpose <STRING> - SUPPORT or COUNTER (optional, default: SUPPORT); selects live policy.
 *
 * Revalidates eligibility, role, enabled state and safety around the dispersed aim point before fire.
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

params [["_battery", objNull, [objNull]], ["_target", [], [[]]], ["_error", 0, [0]], ["_mode", "HE", [""]],
    ["_roundsWanted", -1, [0]], ["_scoot", -1, [0, true]], ["_purpose", "SUPPORT", [""]]];
if (_roundsWanted < 1) then {_roundsWanted = missionNamespace getVariable ["Waldo_AIPass_Artillery_Rounds", 3]};
if (_scoot isEqualType 0) then {_scoot = missionNamespace getVariable ["Waldo_AIPass_Artillery_ShootAndScoot", true]};
if (isNull _battery || {!alive _battery} || {!local _battery} || {!alive gunner _battery} || {count _target < 2}) exitWith {false};
if (!(missionNamespace getVariable ["Waldo_AIPass_Active", false]) || {[] call Waldo_fnc_AIPassIsPaused}
    || {!([group gunner _battery] call Waldo_fnc_AIPassIsEligible)}
    || {!([_battery, _purpose] call Waldo_fnc_AIPassArtilleryRole)}
    || {time < (_battery getVariable ["Waldo_AIPass_BusyUntil", -1])}) exitWith {false};
private _counter = _purpose == "COUNTER";
if !(missionNamespace getVariable [["Waldo_AIPass_Artillery_Enable", "Waldo_AIPass_CounterBattery_Enable"] select _counter, false]) exitWith {false};
private _smoke = toUpperANSI _mode == "SMOKE";
private _best = "";
private _bestHit = -1;
{
    private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
    private _isSmoke = getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") in ["shotSmoke", "shotSmokeX"]
        || {(toLowerANSI _ammo) find "smoke" >= 0} || {(toLowerANSI _x) find "smoke" >= 0};
    private _ammoConfig = configFile >> "CfgAmmo" >> _ammo;
    private _hit = getNumber (_ammoConfig >> "hit");
    // HE means a plain shell: rounds that scatter submunitions (mines, cluster) or illuminate are skipped.
    private _special = getText (_ammoConfig >> "simulation") == "shotIlluminating"
        || {getText (_ammoConfig >> "submunitionAmmo") != ""} || {isArray (_ammoConfig >> "submunitionAmmo")};
    if (_isSmoke == _smoke && {_smoke || {!_special && {_hit > _bestHit}}}) then {_best = _x; _bestHit = _hit};
} forEach (getArtilleryAmmo [_battery]);
if (_best == "") exitWith {false};
private _dispersion = _error + (((_battery distance2D _target) * 0.01) min 150);
private _aim = _target getPos [random _dispersion, random 360];
private _minimum = if (_smoke) then {50} else {
    missionNamespace getVariable [["Waldo_AIPass_Artillery_MinFriendlyDistance", "Waldo_AIPass_CounterBattery_MinFriendlyDistance"] select _counter, 200]
};
private _side = side group gunner _battery;
if ((_aim nearEntities [["CAManBase", "LandVehicle", "Air", "Ship"], _minimum]) findIf {
    private _entity = _x;
    alive _entity && {([_entity] + crew _entity) findIf {
        alive _x && {side _x == civilian || {_side getFriend (side _x) >= 0.6}}
    } >= 0}
} >= 0) exitWith {false};
if !(_aim inRangeOfArtillery [[_battery], _best]) exitWith {false};
private _eta = _battery getArtilleryETA [_aim, _best];
if (_eta < 0) exitWith {false};
private _rounds = [_roundsWanted max 1, 2] select _smoke;
_battery doArtilleryFire [_aim, _best, _rounds];
_battery setVariable ["Waldo_AIPass_BusyUntil", time + _eta + _rounds * 6 + 20];
missionNamespace setVariable ["Waldo_AIPass_ArtilleryMissions", (missionNamespace getVariable ["Waldo_AIPass_ArtilleryMissions", 0]) + 1];
diag_log format ["[WMP AI PASS] Artillery %1 fired %2 x %3 at %4 (eta %5 s)", typeOf _battery, _rounds, _best, _aim, round _eta];
if (_scoot && {!(_battery isKindOf "StaticWeapon")}) then {
    [{
        params ["_job"];
        private _battery = _job get "battery";
        if (alive _battery && {local _battery} && {canMove _battery} && {!isNull driver _battery}
            && {[group driver _battery] call Waldo_fnc_AIPassIsEligible}) then {
            private _group = group driver _battery;
            private _spot = (getPosATL _battery) getPos [200 + random 150, random 360];
            if (!surfaceIsWater _spot && {local _group}) then {[_group, _spot, 30] call Waldo_fnc_AIPassGroupMove};
        };
        -1
    }, createHashMapFromArray [["battery", _battery]], _eta + _rounds * 5 + 10] call Waldo_fnc_AIPassQueueJob;
};
true
