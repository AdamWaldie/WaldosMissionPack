/*
 * Author: WaldoTheWarfighter
 * Updates all local gunship marker positions from local object state.
 *
 * The off-station status HUD is deliberately NOT driven from here - it is revealed only on demand by
 * the "View Off-Station Status" self-interaction (Waldo_fnc_GunshipRevealStatusHud), for a fixed
 * duration, rather than automatically appearing/disappearing every time a controlled gunship's status
 * changes.
 *
 * Locality and authority: runs only on an interface client, driven by the ~1s CBA per-frame
 * handler installed by Waldo_fnc_GunshipSetupLocal. It only reads the already-published
 * Waldo_Gunship_PublicSystems array; it never mutates server state.
 *
 * Arguments: None
 * Return Value: Nothing
 * Example: [] call Waldo_fnc_GunshipUpdateMarkersLocal;
 * Current callers: the gunship marker CBA per-frame handler.
 */

if !(hasInterface) exitWith {};
{
    _x params ["_id", "_aircraft", "_controller", "_status", "_orbit", "", "_side", "_callsign", "", "_showMarkers", ["_serviceCompleteAt", -1], ["_serviceDuration", 0], ["_radius", 1500], ["_altitude", 700], ["_offStationReason", ""]];
    // Own-side only, not merely "friendly" - matches Waldo_fnc_GunshipSetupLocal's own gate.
    private _visible = _showMarkers && {!isNull _aircraft} && {side group player == _side};
    private _aircraftMarkerName = format ["Waldo_Gunship_%1_Aircraft", _id];
    private _orbitMarkerName = format ["Waldo_Gunship_%1_Orbit", _id];
    private _radiusMarkerName = format ["Waldo_Gunship_%1_OrbitRadius", _id];
    if (_visible) then {
        _aircraftMarkerName setMarkerPosLocal getPosWorld _aircraft;
        _aircraftMarkerName setMarkerDirLocal getDir _aircraft;
        _aircraftMarkerName setMarkerTextLocal format ["%1 - %2", _callsign, _status];
        if (count _orbit >= 2) then {
            _orbitMarkerName setMarkerPosLocal _orbit;
            _radiusMarkerName setMarkerPosLocal _orbit;
            _radiusMarkerName setMarkerSizeLocal [_radius, _radius];
        };
    };
} forEach (missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []]);
