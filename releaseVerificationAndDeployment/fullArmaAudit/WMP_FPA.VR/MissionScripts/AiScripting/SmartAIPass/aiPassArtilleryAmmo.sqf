/*
 * Author: WaldoTheWarfighter
 * Selects available smoke or plain HE, excluding illumination and submunitions.
 * Locality/authority: documented guards enforce server coordination and owner-local execution.
 * Repeat/JIP: mission tokens reject stale work; server state survives HC migration, not restart.
 * Arguments: 0: battery <OBJECT>; 1: smoke <BOOL>, default false.
 * Return Value: String magazine class, or empty string.
 * Current callers: ArtilleryFire and ArtilleryShot.
 * Example: private _mag = [_gun, false] call Waldo_fnc_AIPassArtilleryAmmo;
 */
params [["_battery", objNull, [objNull]], ["_smoke", false, [true]]];
private _best = "";
private _available = (magazinesAllTurrets [_battery,true]) select {(_x select 2) > 0};
private _cache = missionNamespace getVariable ["Waldo_AIPass_ArtilleryAmmoProfiles",createHashMap];
private _bestHit = -1;
{
    private _profile = _cache getOrDefault [_x,[]];
    if (_profile isEqualTo []) then {
        private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
        private _cfg = configFile >> "CfgAmmo" >> _ammo;
        private _smokeAmmo = getText (_cfg >> "simulation") in ["shotSmoke","shotSmokeX"] || {(getNumber (_cfg >> "aiAmmoUsageFlags") bitAnd 4) > 0};
        private _specialAmmo = getText (_cfg >> "simulation") == "shotIlluminating" || {getText (_cfg >> "submunitionAmmo") != ""} || {isArray (_cfg >> "submunitionAmmo")};
        _profile = [_smokeAmmo,_specialAmmo,getNumber (_cfg >> "hit")];
        _cache set [_x,_profile];
    };
    _profile params ["_isSmoke","_special","_hit"];
    if (_isSmoke == _smoke && {_smoke || {!_special && {_hit > _bestHit}}}) then {_best = _x; _bestHit = _hit};
} forEach ((getArtilleryAmmo [_battery]) select {private _magazine = _x; _available findIf {(_x select 0) == _magazine} >= 0});
missionNamespace setVariable ["Waldo_AIPass_ArtilleryAmmoProfiles",_cache];

_best
