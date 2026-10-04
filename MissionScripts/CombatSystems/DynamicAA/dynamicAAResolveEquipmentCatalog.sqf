/*
 * Author: WaldoTheWarfighter
 * Live-discovers additional AA-suitable CfgVehicles classes from the running modset, for the ZEN
 * "Exact mixed equipment" pickers and server-side automatic faction profiles. Explicit pools
 * retain priority over discovered classes.
 *
 * Radar structures have no reliable cross-mod "this is a radar" config flag, so radar discovery is
 * inheritance-based: any public class that isKindOf one of the shipped vanilla radar classes (a mod
 * variant of a vanilla radar object almost always inherits from it directly). Mobile AA, static AA
 * and fighters instead get a functional test on top of that same inheritance check: any public
 * vehicle with an air-capable CfgWeapons/CfgAmmo entry on its hull or a nested turret, or an AA
 * editor subcategory, is eligible. Weapon properties live in CfgWeapons/CfgAmmo, not CfgVehicles.
 *
 * Cached once per machine since configuration data is immutable during a mission.
 *
 * Arguments: None.
 *
 * Return Value:
 * HashMap - radarClasses, staticClasses, mobileClasses, fighterClasses <ARRAY<STRING>>
 *
 * Current callers: Waldo_fnc_DynamicAAZen and Waldo_fnc_DynamicAAResolveAssetPool.
 *
 * Example:
 * [] call Waldo_fnc_DynamicAAResolveEquipmentCatalog;
 * Locality and authority: Read-only configuration scan on the requesting curator's client.
 * Repeated calls use current loaded-mod data; no JIP replay is required.
 * Result: Returns labelled equipment choices for the ZEN dialog.
 */
private _cache = missionNamespace getVariable ["Waldo_DynamicAA_EquipmentCatalogCache", createHashMap];
if (count _cache > 0) exitWith {_cache};

private _radarSeeds = ["Land_Radar_F", "B_Radar_System_01_F"];
private _mobileSeeds = ["B_APC_Tracked_01_AA_F", "O_APC_Tracked_02_AA_F", "I_LT_01_AA_F"];
private _staticSeeds = ["B_SAM_System_01_F", "B_AAA_System_01_F"];
private _fighterSeeds = ["B_Plane_Fighter_01_F", "O_Plane_Fighter_02_F", "I_Plane_Fighter_04_F"];

private _hasAirWeapon = {
    private _scan = {
        params ["_vehicleConfig", "_self"];
        private _weapons = getArray (_vehicleConfig >> "weapons");
        private _airWeapon = _weapons findIf {
            private _weaponConfig = configFile >> "CfgWeapons" >> _x;
            isClass _weaponConfig && {
                (getArray (_weaponConfig >> "magazines")) findIf {
                    private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
                    _ammo != "" && {getNumber (configFile >> "CfgAmmo" >> _ammo >> "airLock") > 0}
                } >= 0
            }
        };
        if (_airWeapon >= 0) exitWith {true};
        ("true" configClasses (_vehicleConfig >> "Turrets")) findIf {[_x, _self] call _self} >= 0
    };
    [configFile >> "CfgVehicles" >> _this, _scan] call _scan
};
private _hasAAEditorCategory = {
    private _category = toLower getText (configFile >> "CfgVehicles" >> _this >> "editorSubcategory");
    _category find "aa" >= 0 || {_category find "airdef" >= 0}
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
        || {(_this isKindOf "StaticWeapon") && {(_this call _hasAirWeapon) || {_this call _hasAAEditorCategory}}}
    }
}] call Waldo_fnc_ResolveVehicleClassPool;

private _mobileClasses = ["DYNAMICAA_MOBILE", {
    isClass (configFile >> "CfgVehicles" >> _this)
    && {getNumber (configFile >> "CfgVehicles" >> _this >> "scope") >= 2}
    && {
        ((_mobileSeeds findIf {_this isKindOf _x}) != -1)
        || {(_this isKindOf "LandVehicle") && {!(_this isKindOf "StaticWeapon")} && {(_this call _hasAirWeapon) || {_this call _hasAAEditorCategory}}}
    }
}] call Waldo_fnc_ResolveVehicleClassPool;

private _fighterClasses = ["DYNAMICAA_FIGHTER", {
    isClass (configFile >> "CfgVehicles" >> _this)
    && {getNumber (configFile >> "CfgVehicles" >> _this >> "scope") >= 2}
    && {
        ((_fighterSeeds findIf {_this isKindOf _x}) != -1)
        || {(_this isKindOf "Plane") && {_this call _hasAirWeapon}}
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
