/*
 * Author: WaldoTheWarfighter
 * Authenticates and executes Economy Systems mutations submitted by a ZEN curator client.
 *
 * Economy authoring dialogs run on the curator's interface, but their shared catalogues, side
 * balances and authority lists are server-owned. Calling the authority APIs directly from those
 * dialogs worked on hosted games and silently no-opped on a dedicated client. This bridge keeps
 * the dialogs local while executing the accepted mutation once on the server. It is not a general
 * player request API: a remotely submitted request must belong to an assigned curator.
 *
 * Arguments:
 * 0: operation <STRING> - ADD_RESOURCE, SET_RESOURCE, SET_RESEARCH, SET_BUILD, SET_PURCHASE,
 *    PROMOTE_COMMAND, REMOVE_COMMAND, TOGGLE_MARKERS, APPLY_PRESET, PURGE, PURGE_ALL,
 *    SPAWN_RESOURCE_CRATE, CREATE_RESOURCE_ZONE, SPAWN_RESEARCH_CENTER,
 *    SPAWN_CONFIGURED_BUILDING, SPAWN_CONSTRUCTION_VEHICLE, CREATE_DROP_POINT,
 *    SPAWN_PURCHASE_LAPTOP, SET_COMMITMENT or SET_TEST_NOTICE.
 * 1: payload <ARRAY> - arguments for the selected operation.
 * 2: requester <OBJECT> - curator player that submitted the ZEN dialog.
 *
 * Return Value:
 * BOOL - true when an operation was accepted and executed.
 *
 * Example:
 * ["SET_RESOURCE", ["WEST", "Supplies", 20, name player], player]
 *     remoteExecCall ["Waldo_fnc_EcoCore_zenServerRequest", 2];
 *
 * Current callers:
 * Economy Systems ZEN authoring dialogs and toggles.
 */

params [
    ["_operation", "", [""]],
    ["_payload", [], [[]]],
    ["_requester", objNull, [objNull]]
];

if (!isServer) exitWith {
    [_operation, _payload, player] remoteExecCall ["Waldo_fnc_EcoCore_zenServerRequest", 2];
    true
};

private _requestOwner = if (remoteExecutedOwner > 0) then {remoteExecutedOwner} else {owner _requester};
if (remoteExecutedOwner > 0 && {
    isNull _requester
    || {owner _requester != remoteExecutedOwner}
    || {isNull getAssignedCuratorLogic _requester}
}) exitWith {
    diag_log format ["[WMP ECO ZEN] Rejected operation=%1 owner=%2 reason=UNAUTHORISED", _operation, remoteExecutedOwner];
    false
};

private _result = switch (toUpperANSI _operation) do {
    case "ADD_RESOURCE": {_payload call Waldo_fnc_EcoResource_addResourceType; true};
    case "SET_RESOURCE": {_payload call Waldo_fnc_EcoResource_setSideResourceAmount; true};
    case "SET_RESEARCH": {_payload call Waldo_fnc_EcoResearch_setResearchCatalog; true};
    case "SET_BUILD": {_payload call Waldo_fnc_EcoBuild_setBuildCatalog; true};
    case "SET_PURCHASE": {_payload call Waldo_fnc_EcoBuy_setPurchaseCatalog; true};
    case "PROMOTE_COMMAND": {_payload call Waldo_fnc_EcoCommand_promoteGroundCommand; true};
    case "REMOVE_COMMAND": {_payload call Waldo_fnc_EcoCommand_removeGroundCommand; true};
    case "TOGGLE_MARKERS": {_payload call Waldo_fnc_EcoResource_toggleResourceMarkerVisibility; true};
    case "SPAWN_RESOURCE_CRATE": {_payload call Waldo_fnc_EcoResource_spawnResourceCrate; true};
    case "CREATE_RESOURCE_ZONE": {_payload call Waldo_fnc_EcoResource_createResourceZone; true};
    case "SPAWN_RESEARCH_CENTER": {_payload call Waldo_fnc_EcoResearch_spawnResearchCenter; true};
    case "SPAWN_CONFIGURED_BUILDING": {_payload call Waldo_fnc_EcoBuild_spawnConfiguredBuilding; true};
    case "SPAWN_CONSTRUCTION_VEHICLE": {_payload call Waldo_fnc_EcoBuild_spawnConstructionVehicle; true};
    case "CREATE_DROP_POINT": {_payload call Waldo_fnc_EcoBuy_createDropPoint; true};
    case "SPAWN_PURCHASE_LAPTOP": {_payload call Waldo_fnc_EcoBuy_spawnPurchaseLaptop; true};
    case "SET_COMMITMENT": {_payload call Waldo_fnc_EcoCore_setCommitmentModeEnabled; true};
    case "SET_TEST_NOTICE": {_payload call Waldo_fnc_EcoCore_setTestingNoticeEnabled; true};
    case "APPLY_PRESET": {
        private _response = _payload call Waldo_fnc_EcoCore_applyPresetSelections;
        private _count = _response param [0, 0];
        private _message = _response param [1, "No preset work was performed."];
        if (_requestOwner > 2) then {
            ["ECONOMY PRESET", _message, ["WARNING", "SUCCESS"] select (_count > 0), "ECONOMY_ZEN", 9]
                remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _requestOwner];
        };
        _count > 0
    };
    case "PURGE": {_payload call Waldo_fnc_EcoCore_executeUnifiedPurge};
    case "PURGE_ALL": {
        [] call Waldo_fnc_EcoCore_purgeEconomySystems;
        true
    };
    default {false};
};

// Every operation result consumed below must be a strict BOOL. A third-party or older helper may
// return nil after completing its work; never feed that value into an SQF `if` expression.
if !(_result isEqualType true) then {_result = false};

diag_log format ["[WMP ECO ZEN] operation=%1 owner=%2 result=%3", toUpperANSI _operation, _requestOwner, _result];
if (_requestOwner > 2 && {toUpperANSI _operation != "APPLY_PRESET"}) then {
    [
        "ECONOMY ZEUS",
        if (_result) then {format ["%1 completed on the server.", toUpperANSI _operation]} else {format ["%1 was rejected by the server.", toUpperANSI _operation]},
        if (_result) then {"SUCCESS"} else {"ERROR"},
        "ECONOMY_ZEN",
        7
    ] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _requestOwner];
};
_result
