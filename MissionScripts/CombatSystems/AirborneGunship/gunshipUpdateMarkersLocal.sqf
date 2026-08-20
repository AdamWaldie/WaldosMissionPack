/*
 * Author: WaldoTheWarfighter
 * Updates all local gunship marker positions from local object state, and refreshes the
 * off-station status HUD for whichever registered system currently has this player as its
 * assigned controller.
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
private _statusShown = false;
{
    _x params ["_id", "_aircraft", "_controller", "_status", "_orbit", "", "_side", "_callsign", "", "_showMarkers", ["_serviceCompleteAt", -1], ["_serviceDuration", 0], ["_radius", 1500], ["_altitude", 700], ["_offStationReason", ""]];
    private _visible = _showMarkers && {!isNull _aircraft} && {(side group player) getFriend _side >= 0.6};
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
    // Only one system's off-station panel is shown at a time - a player is realistically never the
    // assigned controller of two gunships simultaneously, and the panel has no room for more than
    // one story at once. First off-station match wins.
    if (!_statusShown && {_controller isEqualTo player} && {!(_status in ["ON_STATION", "CONTROLLED"])}) then {
        [true, _callsign, _status, _offStationReason, _serviceCompleteAt] call Waldo_fnc_GunshipStatusHud;
        _statusShown = true;
    };
} forEach (missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []]);
if !(_statusShown) then {
    [false] call Waldo_fnc_GunshipStatusHud;
};
