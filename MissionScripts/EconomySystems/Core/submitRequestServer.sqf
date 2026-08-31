/*
 * Author: WaldoTheWarfighter
 * Submit one Economy player request directly to server authority.
 *
 * Locality / Authority:
 * May be called by an interface client or the server. Client calls forward once to the server;
 * the server dispatches the unchanged request payload to the existing authoritative processor.
 * No request state is published to other clients and no JIP entry is created.
 *
 * Repeat / JIP Behaviour:
 * Repeat requests retain the existing request-token handling in each processor. JIP clients use
 * the same local actions and submit only actions they perform after joining.
 *
 * Arguments:
 * 0: _operation <STRING> - ZONE_CAPTURE, CRATE_COLLECT, START_RESEARCH,
 *    START_CONSTRUCTION, MANAGE_BUILDING, or PURCHASE
 * 1: _target <OBJECT> - request holder used by the existing processor
 * 2: _request <ARRAY> - existing processor request payload, unchanged
 *
 * Return Value:
 * <BOOLEAN> - true when the request was forwarded or dispatched; false when malformed/inactive
 *
 * Current Callers:
 * Economy resource, research, construction, building-management and purchase client actions.
 *
 * Example:
 * ["CRATE_COLLECT", _crate, [netId player, getPlayerUID player, name player, _token]]
 *     call Waldo_fnc_EcoCore_submitRequestServer;
 */

params [
    ["_operation", "", [""]],
    ["_target", objNull, [objNull]],
    ["_request", [], [[]]]
];

if (_operation isEqualTo "" || {isNull _target} || {_request isEqualTo []}) exitWith {false};

if (!isServer) exitWith {
    [_operation, _target, _request] remoteExecCall ["Waldo_fnc_EcoCore_submitRequestServer", 2];
    true
};

if !([] call Waldo_fnc_EcoCore_isModuleActive) exitWith {false};

private _dispatched = switch (_operation) do {
    case "ZONE_CAPTURE": {
        [_target, _request] call Waldo_fnc_EcoResource_processZoneCaptureRequest;
        true
    };
    case "CRATE_COLLECT": {
        [_target, _request] call Waldo_fnc_EcoResource_processCrateCollectRequest;
        true
    };
    case "START_RESEARCH": {
        [_target, _request] call Waldo_fnc_EcoResearch_processStartResearchRequest;
        true
    };
    case "START_CONSTRUCTION": {
        [_target, _request] call Waldo_fnc_EcoBuild_processStartConstructionRequest;
        true
    };
    case "MANAGE_BUILDING": {
        [_target, _request] call Waldo_fnc_EcoBuild_processBuildingManageRequest;
        true
    };
    case "PURCHASE": {
        [_target, _request] call Waldo_fnc_EcoBuy_processPurchaseRequest;
        true
    };
    default {
        false
    };
};

_dispatched
