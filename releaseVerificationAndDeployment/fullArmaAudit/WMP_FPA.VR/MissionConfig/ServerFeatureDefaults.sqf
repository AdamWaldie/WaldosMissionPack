/*
 * Author: WaldoTheWarfighter
 * Defines and publishes server-authoritative feature defaults. It must run on the server only,
 * before server feature activation. Existing mission-maker and live values are preserved where
 * applicable, while published values use Arma's JIP-safe missionNamespace broadcast.
 *
 * Arguments: None.
 * Return Value: Nothing; server-owned defaults are installed and published.
 *
 * Example: call compile preprocessFileLineNumbers "MissionConfig\ServerFeatureDefaults.sqf";
 * Current caller: initServer.sqf immediately after the authoritative ACRE plan starts.
 */
if (!isServer) exitWith {};

if (isNil "Waldo_ObjectScaling_Minimum") then {Waldo_ObjectScaling_Minimum = 0.1};
if (isNil "Waldo_ObjectScaling_Maximum") then {Waldo_ObjectScaling_Maximum = 10};
if (isNil "Waldo_ObjectScaling_AllowClientRequests") then {Waldo_ObjectScaling_AllowClientRequests = false};

if (isNil "Waldo_DynamicAA_DefaultDetectionInterval") then {Waldo_DynamicAA_DefaultDetectionInterval = 1};
if (isNil "Waldo_DynamicAA_MaximumRadius") then {Waldo_DynamicAA_MaximumRadius = 50000};
if (isNil "Waldo_DynamicAA_MaximumAltitude") then {Waldo_DynamicAA_MaximumAltitude = 10000};
if (isNil "Waldo_DynamicAA_MaximumFighters") then {Waldo_DynamicAA_MaximumFighters = 12};
if (isNil "Waldo_DynamicAA_SideAssetPools") then {
    Waldo_DynamicAA_SideAssetPools = createHashMapFromArray [
        ["WEST", createHashMapFromArray [
            ["radarClasses", ["B_Radar_System_01_F", "Land_Radar_F"]],
            ["staticSitePools", [["B_Radar_System_01_F", "B_SAM_System_01_F", "B_AAA_System_01_F"]]],
            ["mobileClasses", ["B_APC_Tracked_01_AA_F"]],
            ["fighterClasses", ["B_Plane_Fighter_01_F", "B_Plane_Fighter_01_Stealth_F"]]
        ]],
        ["EAST", createHashMapFromArray [
            ["radarClasses", ["O_Radar_System_02_F", "Land_Radar_F"]],
            ["staticSitePools", [["O_Radar_System_02_F", "O_SAM_System_04_F", "B_AAA_System_01_F"]]],
            ["mobileClasses", ["O_APC_Tracked_02_AA_F", "O_T_APC_Tracked_02_AA_ghex_F"]],
            ["fighterClasses", ["O_Plane_Fighter_02_F", "O_Plane_Fighter_02_Stealth_F"]]
        ]],
        ["INDEPENDENT", createHashMapFromArray [
            ["radarClasses", ["I_E_Radar_System_01_F", "Land_Radar_F"]],
            ["staticSitePools", [["I_E_Radar_System_01_F", "I_E_SAM_System_03_F", "B_AAA_System_01_F"]]],
            ["mobileClasses", ["I_LT_01_AA_F"]],
            ["fighterClasses", ["I_Plane_Fighter_03_dynamicLoadout_F"]]
        ]]
    ];
};
if (isNil "Waldo_DynamicAA_FactionAssetPools") then {Waldo_DynamicAA_FactionAssetPools = createHashMap};
missionNamespace setVariable ["Waldo_DynamicAA_SideAssetPools", Waldo_DynamicAA_SideAssetPools, true];
missionNamespace setVariable ["Waldo_DynamicAA_FactionAssetPools", Waldo_DynamicAA_FactionAssetPools, true];

{
    _x params ["_name", "_default"];
    missionNamespace setVariable [_name, missionNamespace getVariable [_name, _default], true];
} forEach [
    ["Waldo_Jamming_Enable", true], ["Waldo_Jamming_Notify", true], ["Waldo_Jamming_LOS", true],
    ["Waldo_Jamming_BurnThrough", true], ["Waldo_Jamming_BurnThroughRef", 500],
    ["Waldo_Jamming_Curve", "LINEAR"], ["Waldo_Jamming_Destructible", true],
    ["Waldo_Jamming_GmOverlay", false], ["Waldo_Jamming_ScanRange", 3000],
    ["Waldo_Jamming_ScanBearingArc", 30], ["Waldo_Jamming_ScanDistanceBands", [35, 150, 600]],
    ["Waldo_Jamming_AllowPlayerToggle", true], ["Waldo_Jamming_DisableChallenge", false],
    ["Waldo_Jamming_DisableChallengeId", "circuit"], ["Waldo_Jamming_DisableDifficulty", "standard"],
    ["Waldo_Jamming_DisableEngineerOnly", true], ["Waldo_Jamming_DisableResult", "DISABLE"]
];
missionNamespace setVariable ["Waldo_Jamming_ConfigReady", true, true];

missionNamespace setVariable ["Logi_SupplyBoxClass", missionNamespace getVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F"], true];
private _medicalDefault = if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {"ACE_medicalSupplyCrate_advanced"} else {"C_IDAP_supplyCrate_F"};
missionNamespace setVariable ["Logi_MedicalBoxClass", missionNamespace getVariable ["Logi_MedicalBoxClass", _medicalDefault], true];

missionNamespace setVariable ["WALDO_STATIC_MINALTITUDE", missionNamespace getVariable ["WALDO_STATIC_MINALTITUDE", 180], true];
missionNamespace setVariable ["WALDO_STATIC_MAXALTITUDE", missionNamespace getVariable ["WALDO_STATIC_MAXALTITUDE", 350], true];
missionNamespace setVariable ["WALDO_STATIC_MAXSPEED", missionNamespace getVariable ["WALDO_STATIC_MAXSPEED", 310], true];
missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE", missionNamespace getVariable ["WALDO_STATIC_STATICCHUTE", "rhs_d6_Parachute"], true];
missionNamespace setVariable ["WALDO_PARA_HALOALTITUDE", missionNamespace getVariable ["WALDO_PARA_HALOALTITUDE", 1000], true];
missionNamespace setVariable ["WALDO_PARA_HALOCHUTE", missionNamespace getVariable ["WALDO_PARA_HALOCHUTE", "B_Parachute"], true];

missionNamespace setVariable ["Waldo_RunDiagnostics", missionNamespace getVariable ["Waldo_RunDiagnostics", true], true];
missionNamespace setVariable ["Waldo_SafeStart_Confine", missionNamespace getVariable ["Waldo_SafeStart_Confine", true], true];
missionNamespace setVariable ["Waldo_SafeStart_Radius", missionNamespace getVariable ["Waldo_SafeStart_Radius", 75], true];
missionNamespace setVariable ["Waldo_SafeStart_ZoneMarker", missionNamespace getVariable ["Waldo_SafeStart_ZoneMarker", ""], true];
missionNamespace setVariable ["Waldo_SafeStart_AutoStart", missionNamespace getVariable ["Waldo_SafeStart_AutoStart", true], true];
