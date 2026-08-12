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
 * Current callers: initPlayerLocal.sqf unconditionally, plus Waldo_fnc_ParadropCreateDropZone,
 * Waldo_fnc_ParadropRemoveDropZone and Waldo_fnc_ParadropQuickFlightSetup when state changes.
 */

if !(hasInterface) exitWith {false};
if (isNil {missionNamespace getVariable "Waldo_Paradrop_MarkerPFH"}) then {
    private _handler = [{[] call Waldo_fnc_ParadropUpdateMarkersLocal}, 1] call CBA_fnc_addPerFrameHandler;
    missionNamespace setVariable ["Waldo_Paradrop_MarkerPFH", _handler];
    diag_log format ["[WMP PARADROP] Live aircraft marker reconciler started clientOwner=%1.", clientOwner];
};

private _systems = missionNamespace getVariable ["Waldo_Paradrop_PublicAircraft", []];
private _systemIds = _systems apply {_x select 0};
private _knownIds = missionNamespace getVariable ["Waldo_Paradrop_LocalIds", []];
{
    if !(_x in _systemIds) then {deleteMarkerLocal format ["Waldo_Paradrop_%1_Aircraft", _x]};
} forEach _knownIds;
missionNamespace setVariable ["Waldo_Paradrop_LocalIds", _systemIds];

{
    _x params ["_id", "_name", "_aircraft", "_side"];
    private _markerName = format ["Waldo_Paradrop_%1_Aircraft", _id];
    if (!isNull _aircraft && {alive _aircraft} && {(side group player) getFriend _side >= 0.6}) then {
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
