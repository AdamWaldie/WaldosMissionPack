/*
Waldos Economy Systems - mission-maker economy authoring file
=============================================================

This is THE place to hand-author your economy in the editor (resources, research, buildings,
purchases) and to pre-place economy world objects (resource zones, crates, research centers,
purchase terminals, drop points) at map markers - all without opening Zeus.

How it runs:
  - Called automatically, ONCE, on the server authority by Waldo_fnc_EcoCore_applyMakerConfig
    (after any preset / config string from initServer.sqf is applied). Registered as
    Waldo_fnc_EcoMakerSetup.
  - Every catalogue/placement call below is server-authoritative and broadcast, so JIP and
    rejoining players inherit the configured economy automatically. Do NOT add per-client code.

Prerequisites:
  - Enable the suite (init.sqf: Waldo_Economy_Enable = true;) or place a Waldos Economy
    Systems composition. If the suite is disabled, this file does nothing.

Quick start:
  - The block below is a complete, working example economy. Set _useExample to true to load it,
    or leave it false and write your own definitions in the "YOUR ECONOMY" section further down.

Helper reference (all server-authoritative):
  Resources : [name, "#hexColour", "iconPath", storageCap] call Waldo_fnc_EcoResource_addResourceType;
              (storageCap -1 = unlimited)
  Research  : [[ [name, desc, costRows, requirementList, timeSeconds] , ... ]] call Waldo_fnc_EcoResearch_setResearchCatalog;
  Buildings : [[ [name, desc, costRows, requirementList, timeSeconds, "", "", false, "ClassName", produceResource, produceAmount, produceInterval] , ... ]] call Waldo_fnc_EcoBuild_setBuildCatalog;
  Purchases : [[ [name, desc, costRows, requirementList, "ClassName", "Ground"/"Air"/"Naval", "EVERYONE"] , ... ]] call Waldo_fnc_EcoBuy_setPurchaseCatalog;
  costRows  : [["Resource Name", amount], ...]      requirementList : ["Some Research", "Some Building"]

  Place objects (positions or getMarkerPos "name"):
  Resource zone : [_pos, "Name", radius, [["Resource", amountPerTick, depositCap]], "WEST"/"EAST"/"GUER"/"NONE", intervalSeconds] call Waldo_fnc_EcoResource_createResourceZone;
  Resource crate: [_pos, [["Resource", amount]]] call Waldo_fnc_EcoResource_spawnResourceCrate;
  Research center: [_pos] call Waldo_fnc_EcoResearch_spawnResearchCenter;
  Purchase drop : [_pos, "Ground"/"Air"/"Naval", dir, "ANY"] call Waldo_fnc_EcoBuy_createDropPoint;

  ...or place a VANILLA object in Eden and designate it from its init field:
  Land_Research_HQ_F       -> [this] call Waldo_fnc_EcoResearch_registerCenter;
  Land_Laptop_unfolded_F   -> [this] call Waldo_fnc_EcoBuy_registerTerminal;
  any vehicle              -> [this] call Waldo_fnc_EcoBuild_registerConstructionVehicle;
*/

if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

private _icon = call Waldo_fnc_EcoResource_getDefaultResourceIcon;

// ============================================================================================
//  WORKED EXAMPLE  (set to true to load this ready-made economy)
// ============================================================================================
private _useExample = false;

if (_useExample) then {
    // --- Resources -------------------------------------------------------------------------
    ["Supplies", "#D4C15A", _icon, -1] call Waldo_fnc_EcoResource_addResourceType;   // unlimited
    ["Fuel",     "#8ED1FC", _icon, 50] call Waldo_fnc_EcoResource_addResourceType;   // cap 50

    // --- Research --------------------------------------------------------------------------
    [[
        ["Logistics I",  "Basic supply handling.",              [["Supplies", 10]], [],               60],
        ["Vehicle Depot","Unlocks transport purchases.",        [["Supplies", 20]], ["Logistics I"], 120]
    ]] call Waldo_fnc_EcoResearch_setResearchCatalog;

    // --- Buildings -------------------------------------------------------------------------
    [[
        ["Generator",    "Produces fuel over time.",            [["Supplies", 15]], [],  90, "", "", false, "Land_PowerGenerator_F", "Fuel", 2, 20],
        ["Supply Depot", "A forward logistics building.",       [["Supplies", 10]], [],  60, "", "", false, "Land_Cargo_HQ_V1_F"]
    ]] call Waldo_fnc_EcoBuild_setBuildCatalog;

    // --- Purchases -------------------------------------------------------------------------
    [[
        ["Transport Truck", "A cargo truck.",                   [["Supplies", 10]], ["Vehicle Depot"], "B_Truck_01_transport_F", "Ground", "EVERYONE"]
    ]] call Waldo_fnc_EcoBuy_setPurchaseCatalog;

    // --- World objects (only placed if the matching marker exists) --------------------------
    private _zonePos = getMarkerPos "eco_zone_1";
    if !(_zonePos isEqualTo [0,0,0]) then {
        [_zonePos, "Supply Field", 30, [["Supplies", 2, 500]], "NONE", 30] call Waldo_fnc_EcoResource_createResourceZone;
    };

    private _rcPos = getMarkerPos "eco_research_1";
    if !(_rcPos isEqualTo [0,0,0]) then {
        [_rcPos] call Waldo_fnc_EcoResearch_spawnResearchCenter;
    };
};

// ============================================================================================
//  YOUR ECONOMY  (write your own definitions here)
// ============================================================================================
// ["Money", "#7BC86A", _icon, -1] call Waldo_fnc_EcoResource_addResourceType;
//
// [[ ["My Research", "Description.", [["Money", 5]], [], 60] ]] call Waldo_fnc_EcoResearch_setResearchCatalog;
//
// [[ ["My Building", "Description.", [["Money", 10]], [], 60, "", "", false, "Land_Cargo_HQ_V1_F"] ]] call Waldo_fnc_EcoBuild_setBuildCatalog;
//
// [[ ["My Vehicle", "Description.", [["Money", 8]], [], "B_MRAP_01_F", "Ground", "EVERYONE"] ]] call Waldo_fnc_EcoBuy_setPurchaseCatalog;
