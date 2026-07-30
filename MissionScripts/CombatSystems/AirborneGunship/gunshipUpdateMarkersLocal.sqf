/*
 * Author: WaldoTheWarfighter
 * Updates all local gunship marker positions from local object state.
 * Arguments: None
 * Return Value: Nothing
 */

if !(hasInterface) exitWith {};
{
    _x params ["_id", "_aircraft", "", "_status", "_orbit", "", "_side", "_callsign", "", "_showMarkers"];
    private _visible = _showMarkers && {!isNull _aircraft} && {(side group player) getFriend _side >= 0.6};
    private _aircraftMarkerName = format ["Waldo_Gunship_%1_Aircraft", _id];
    private _orbitMarkerName = format ["Waldo_Gunship_%1_Orbit", _id];
    if (_visible) then {
        _aircraftMarkerName setMarkerPosLocal getPosWorld _aircraft;
        _aircraftMarkerName setMarkerDirLocal getDir _aircraft;
        _aircraftMarkerName setMarkerTextLocal format ["%1 - %2", _callsign, _status];
        if (count _orbit >= 2) then {_orbitMarkerName setMarkerPosLocal _orbit};
    };
} forEach (missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []]);
