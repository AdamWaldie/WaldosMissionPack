/*
 * Author: WaldoTheWarfighter
 * Selects available smoke (including smoke deployers) or plain HE; excludes illumination and mixed payloads.
 * Locality/authority: read-only query on the battery owner; callers coordinate fire on the server.
 * Repeat/JIP: repeat-safe; immutable ammunition profiles are cached locally, available rounds are read each call.
 * Arguments: 0: battery <OBJECT>, default objNull; 1: smoke <BOOL>, default false.
 * Return Value: String magazine class, or empty string.
 * Current callers: ArtilleryFire and ArtilleryShot.
 * Example: private _mag = [_gun, false] call Waldo_fnc_CortexArtilleryAmmo;
 */
params [["_battery", objNull, [objNull]], ["_smoke", false, [true]]];
private _best = "";
private _available = (magazinesAllTurrets [_battery,true]) select {(_x select 2) > 0};
private _cache = missionNamespace getVariable ["Waldo_AIPass_ArtilleryAmmoProfiles",createHashMap];
private _bestHit = -1;
// Mortar smoke can be a shotDeploy carrier rather than a direct smoke projectile.
// Inspect only immutable config, bounded against recursive addon payload definitions.
private _classifySmoke = {
    params ["_ammoClass",["_depth",0]];
    if (_depth >= 4 || {!isClass (configFile >> "CfgAmmo" >> _ammoClass)}) exitWith {false};
    private _ammoConfig = configFile >> "CfgAmmo" >> _ammoClass;
    private _simulation = toLowerANSI getText (_ammoConfig >> "simulation");
    if (_simulation in ["shotsmoke","shotsmokex"]) exitWith {true};
    if (_simulation != "shotdeploy") exitWith {
        (floor (getNumber (_ammoConfig >> "aiAmmoUsageFlags") / 4) mod 2) == 1
    };
    if (getNumber (_ammoConfig >> "hit") > 0 || {getNumber (_ammoConfig >> "indirectHit") > 0}) exitWith {false};
    private _payload = getText (_ammoConfig >> "submunitionAmmo");
    private _payloads = if (_payload != "") then {[_payload]} else {
        (getArray (_ammoConfig >> "submunitionAmmo")) select {_x isEqualType ""}
    };
    _payloads isNotEqualTo [] && {_payloads findIf {!([_x,_depth+1] call _classifySmoke)} < 0}
};
{
    private _profile = _cache getOrDefault [_x,[]];
    if (_profile isEqualTo []) then {
        private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
        private _cfg = configFile >> "CfgAmmo" >> _ammo;
        private _smokeAmmo = [_ammo] call _classifySmoke;
        private _specialAmmo = getText (_cfg >> "simulation") == "shotIlluminating" || {getText (_cfg >> "submunitionAmmo") != ""} || {isArray (_cfg >> "submunitionAmmo")};
        _profile = [_smokeAmmo,_specialAmmo,getNumber (_cfg >> "hit")];
        _cache set [_x,_profile];
    };
    _profile params ["_isSmoke","_special","_hit"];
    if (_isSmoke == _smoke && {_smoke || {!_special && {_hit > _bestHit}}}) then {_best = _x; _bestHit = _hit};
} forEach ((getArtilleryAmmo [_battery]) select {private _magazine = _x; _available findIf {(_x select 0) == _magazine} >= 0});
missionNamespace setVariable ["Waldo_AIPass_ArtilleryAmmoProfiles",_cache];

_best
