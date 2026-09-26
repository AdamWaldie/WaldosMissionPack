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

_best
