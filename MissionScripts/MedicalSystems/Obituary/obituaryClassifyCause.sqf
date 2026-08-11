/*
 * Author: WaldoTheWarfighter
 * Classifies a player death into a human-readable cause-of-death string for the Obituary KIA
 * report. Ordered so more specific cases (self, own vehicle, friendly fire, explosive ordnance,
 * static/emplaced weapons, unmanned systems) are checked before the broader vehicle-class
 * catch-alls they would otherwise be swallowed by - StaticWeapon in particular isKindOf
 * "LandVehicle", so it must be classified before the generic land-vehicle case.
 * Locality and authority: pure helper, no side effects; safe to call on any machine. Callers must
 * pass already-cached values (never re-derive names/state from a possibly-disconnected object).
 *
 * Arguments:
 * 0: Victim <OBJECT> - the dead unit
 * 1: Killer <OBJECT> - the immediate cause object from the Killed event (may be null)
 * 2: Instigator <OBJECT> - the credited instigator (falls back to killer when null upstream)
 * 3: Shot <OBJECT or STRING> - the projectile/ammo/charge object or classname from the Killed event
 * 4: Is friendly fire <BOOL> - whether this death was already classified as friendly fire
 * 5: Instigator name <STRING> - cached display name of the instigator, used in the friendly-fire case
 *
 * Return Value:
 * String - the classified cause-of-death text
 *
 * Example:
 * [_unit, _killer, _instigator, _shot, _isFriendlyFire, _instigatorName] call Waldo_fnc_ObituaryClassifyCause;
 * Result: "Explosive ordnance (mine/charge)" for a death attributed to a placed mine/charge object.
 * Current caller: Waldo_fnc_ObituaryRecordDeath, at the moment of death while objects are still valid.
 *
 * Note: "TimeBombCore" (remote-detonated satchel/demo charges) is standard Arma 3 config knowledge
 * not independently verified from this repo - confirm with
 * isClass (configFile >> "CfgVehicles" >> "TimeBombCore") in the editor debug console if the
 * explosive-ordnance case ever needs auditing.
 */

params ["_unit", "_killer", "_instigator", "_shot", "_isFriendlyFire", "_instigatorName"];

switch (true) do {
    case (isNull _killer): {"Unknown"};
    case (_killer == _unit): {"Accident"};
    case (vehicle _unit != _unit && {_killer == vehicle _unit}): {"Vehicle accident"};
    case (_isFriendlyFire): {format ["Friendly fire (%1)", _instigatorName]};
    case (
        (_killer isKindOf "Mine") || (_killer isKindOf "TimeBombCore")
        || (_shot isEqualType objNull && {!isNull _shot} && {(_shot isKindOf "Mine") || (_shot isKindOf "TimeBombCore")})
    ): {"Explosive ordnance (mine/charge)"};
    case (_killer isKindOf "StaticWeapon"): {"Static/emplaced weapon fire"};
    case (unitIsUAV _killer): {"Unmanned system (UAV/UGV) fire"};
    case (_killer isKindOf "Air"): {"Air strike"};
    case (_killer isKindOf "Ship"): {"Naval/watercraft fire"};
    case (_killer isKindOf "Tank"): {"Armoured vehicle fire"};
    case (_killer isKindOf "LandVehicle"): {"Vehicle fire"};
    case (_killer isKindOf "CAManBase"): {"Enemy fire"};
    default {"Unknown cause"};
};
