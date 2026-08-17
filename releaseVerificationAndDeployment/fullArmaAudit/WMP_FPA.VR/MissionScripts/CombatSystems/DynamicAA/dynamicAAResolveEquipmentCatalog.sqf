/*
 * Author: WaldoTheWarfighter
 * Live-discovers additional AA-suitable CfgVehicles classes from the running modset, for the ZEN
 * "Exact mixed equipment" pickers only - it never touches Waldo_fnc_DynamicAAResolveAssetPool's own
 * side/faction asset-pool contract, exactly like Waldo_fnc_ResolveFactionCatalog only extends the
 * Faction-profile picker without changing what a chosen faction's pool actually contains.
 *
 * Radar structures have no reliable cross-mod "this is a radar" config flag, so radar discovery is
 * inheritance-based: any public class that isKindOf one of the shipped vanilla radar classes (a mod
 * variant of a vanilla radar object almost always inherits from it directly). Mobile AA, static AA
 * and fighters instead get a functional test on top of that same inheritance check: any public
 * vehicle whose config carries a turret weapon with canLock covering air targets (canLock 2 or 3,
 * the same vanilla/modded attribute that drives a real air-lock capability, checked recursively via
 * configProperties so a nested sub-turret's weapon still counts) - a wholly new mod AA system that
 * does not inherit from any vanilla AA class is still found this way.
 *
 * Cached once per machine since configuration data is immutable during a mission.
 *
 * Arguments: None.
 *
 * Return Value:
 * HashMap - radarClasses, staticClasses, mobileClasses, fighterClasses <ARRAY<STRING>>
 *
 * Current caller: Waldo_fnc_DynamicAAZen.
 *
 * Example:
 * [] call Waldo_fnc_DynamicAAResolveEquipmentCatalog;
 */
private _cache = missionNamespace getVariable ["Waldo_DynamicAA_EquipmentCatalogCache", createHashMap];
if (count _cache > 0) exitWith {_cache};

private _radarSeeds = ["Land_Radar_F", "B_Radar_System_01_F"];
private _mobileSeeds = ["B_APC_Tracked_01_AA_F", "O_APC_Tracked_02_AA_F", "I_LT_01_AA_F"];
private _staticSeeds = ["B_SAM_System_01_F", "B_AAA_System_01_F"];
private _fighterSeeds = ["B_Plane_Fighter_01_F", "O_Plane_Fighter_02_F", "I_Plane_Fighter_04_F"];

private _hasAirLockWeapon = {
    // _this = classname. True when any turret weapon anywhere in the config tree (including a
    // nested sub-turret) can lock an air target.
    count (configProperties [
        configFile >> "CfgVehicles" >> _this,
        "isNumber (_x >> 'canLock') && {(getNumber (_x >> 'canLock')) in [2, 3]}",
        true
    ]) > 0
};

private _radarClasses = ["DYNAMICAA_RADAR", {
    isClass (configFile >> "CfgVehicles" >> _this)
    && {getNumber (configFile >> "CfgVehicles" >> _this >> "scope") >= 2}
    && {(_radarSeeds findIf {_this isKindOf _x}) != -1}
}] call Waldo_fnc_ResolveVehicleClassPool;

private _staticClasses = ["DYNAMICAA_STATIC", {
    isClass (configFile >> "CfgVehicles" >> _this)
    && {getNumber (configFile >> "CfgVehicles" >> _this >> "scope") >= 2}
    && {
        ((_staticSeeds findIf {_this isKindOf _x}) != -1)
        || {(_this isKindOf "StaticWeapon") && {_this call _hasAirLockWeapon}}
    }
}] call Waldo_fnc_ResolveVehicleClassPool;

private _mobileClasses = ["DYNAMICAA_MOBILE", {
    isClass (configFile >> "CfgVehicles" >> _this)
    && {getNumber (configFile >> "CfgVehicles" >> _this >> "scope") >= 2}
    && {
        ((_mobileSeeds findIf {_this isKindOf _x}) != -1)
        || {(_this isKindOf "LandVehicle") && {!(_this isKindOf "StaticWeapon")} && {_this call _hasAirLockWeapon}}
    }
}] call Waldo_fnc_ResolveVehicleClassPool;

private _fighterClasses = ["DYNAMICAA_FIGHTER", {
    isClass (configFile >> "CfgVehicles" >> _this)
    && {getNumber (configFile >> "CfgVehicles" >> _this >> "scope") >= 2}
    && {
        ((_fighterSeeds findIf {_this isKindOf _x}) != -1)
        || {(_this isKindOf "Plane") && {_this call _hasAirLockWeapon}}
    }
}] call Waldo_fnc_ResolveVehicleClassPool;

_cache = createHashMapFromArray [
    ["radarClasses", _radarClasses apply {_x select 0}],
    ["staticClasses", _staticClasses apply {_x select 0}],
    ["mobileClasses", _mobileClasses apply {_x select 0}],
    ["fighterClasses", _fighterClasses apply {_x select 0}]
];
missionNamespace setVariable ["Waldo_DynamicAA_EquipmentCatalogCache", _cache];
_cache
