/*
 * Author: WaldoTheWarfighter
 * Reconciles JIP-safe live paradrop aircraft markers on one client.
 *
 * Consumes Waldo_Paradrop_PublicAircraft - the broadcast, server-owned list of currently active
 * paradrop aircraft fed by both Waldo_fnc_ParadropQuickFlightSetup and the Dynamic Drop Zone system
 * (Waldo_fnc_ParadropCreateDropZone/RemoveDropZone) - and creates/updates/removes one live b_plane
 * marker per aircraft, the same pattern Waldo_fnc_GunshipSetupLocal already uses for airborne
 * gunships: a marker that tracks the aircraft's actual position/heading every frame instead of the
 * static corridor markers created once at setup time. This is what makes a pre-placed drop zone
 * marker feel "replaced" by the live aircraft once it starts flying, rather than leaving only ever a
 * fixed target/corridor on the map with no sense of where the plane currently is.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true after local reconciliation
 *
 * Example:
 * [] call Waldo_fnc_ParadropSetupLocal;
 * Repeat/JIP behaviour: repeat-safe. One event-driven listener reconciles arrival of the custom
 * public registry without polling. The live-marker handler exists only while at least one published
 * aircraft exists; state-change calls start it for the first aircraft and remove it after the last.
 * Active aircraft keep the existing one-second live marker cadence.
 * Current callers: initPlayerLocal.sqf, plus Waldo_fnc_ParadropCreateDropZone,
 * Waldo_fnc_ParadropRemoveDropZone and Waldo_fnc_ParadropQuickFlightSetup when state changes.
 */

if !(hasInterface) exitWith {false};
// Arma transports the custom registry, but applying its marker side effects remains client-local.
// The registry may arrive before or after the explicit setup call during JIP, so cover both orders
// without retaining an empty per-frame handler for the entire mission.
if !(missionNamespace getVariable ["Waldo_Paradrop_PublicAircraftEHInstalled", false]) then {
    "Waldo_Paradrop_PublicAircraft" addPublicVariableEventHandler {
        [] call Waldo_fnc_ParadropSetupLocal;
    };
    missionNamespace setVariable ["Waldo_Paradrop_PublicAircraftEHInstalled", true];
};
private _systems = missionNamespace getVariable ["Waldo_Paradrop_PublicAircraft", []];
private _markerHandler = missionNamespace getVariable ["Waldo_Paradrop_MarkerPFH", -1];
if (_systems isEqualTo []) then {
    if (_markerHandler >= 0) then {
        [_markerHandler] call CBA_fnc_removePerFrameHandler;
        missionNamespace setVariable ["Waldo_Paradrop_MarkerPFH", nil];
        diag_log format ["[WMP PARADROP] Live aircraft marker reconciler stopped clientOwner=%1; no aircraft remain.", clientOwner];
    };
} else {
    if (_markerHandler < 0) then {
        _markerHandler = [{[] call Waldo_fnc_ParadropUpdateMarkersLocal}, 1] call CBA_fnc_addPerFrameHandler;
        missionNamespace setVariable ["Waldo_Paradrop_MarkerPFH", _markerHandler];
        diag_log format ["[WMP PARADROP] Live aircraft marker reconciler started clientOwner=%1.", clientOwner];
    };
};

private _systemIds = _systems apply {_x select 0};
private _knownIds = missionNamespace getVariable ["Waldo_Paradrop_LocalIds", []];
{
    if !(_x in _systemIds) then {deleteMarkerLocal format ["Waldo_Paradrop_%1_Aircraft", _x]};
} forEach _knownIds;
missionNamespace setVariable ["Waldo_Paradrop_LocalIds", _systemIds];

{
    _x params ["_id", "_name", "_aircraft", "_side"];
    private _markerName = format ["Waldo_Paradrop_%1_Aircraft", _id];
    // Own-side only, not merely "friendly" - a player must not see another side's paradrop aircraft
    // marker just because the two sides are friendly under vanilla default relations.
    if (!isNull _aircraft && {alive _aircraft} && {side group player == _side}) then {
        if (markerShape _markerName == "") then {
            createMarkerLocal [_markerName, getPosWorld _aircraft];
            _markerName setMarkerTypeLocal "b_plane";
            _markerName setMarkerColorLocal (switch (_side) do {
                case east: {"ColorOPFOR"};
                case independent: {"ColorIndependent"};
                case civilian: {"ColorCivilian"};
                default {"ColorBLUFOR"};
            });
        };
        _markerName setMarkerPosLocal getPosWorld _aircraft;
        _markerName setMarkerDirLocal getDir _aircraft;
        _markerName setMarkerTextLocal _name;
    } else {
        deleteMarkerLocal _markerName;
    };
} forEach _systems;
true
