/*
 * Author: WaldoTheWarfighter
 * Updates all local paradrop aircraft marker positions from local object state.
 *
 * Companion tick to Waldo_fnc_ParadropSetupLocal, mirroring how
 * Waldo_fnc_GunshipUpdateMarkersLocal keeps the airborne gunship aircraft marker live - same
 * per-frame position/heading refresh, same friendly-side visibility test, same reliance on the
 * marker already existing (created once by Waldo_fnc_ParadropSetupLocal, not here).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_ParadropUpdateMarkersLocal;
 * Current caller: the per-frame handler installed once by Waldo_fnc_ParadropSetupLocal.
 */

if !(hasInterface) exitWith {};
{
    _x params ["_id", "_name", "_aircraft", "_side"];
    private _visible = !isNull _aircraft && {alive _aircraft} && {(side group player) getFriend _side >= 0.6};
    if (_visible) then {
        private _markerName = format ["Waldo_Paradrop_%1_Aircraft", _id];
        _markerName setMarkerPosLocal getPosWorld _aircraft;
        _markerName setMarkerDirLocal getDir _aircraft;
        _markerName setMarkerTextLocal _name;
    };
} forEach (missionNamespace getVariable ["Waldo_Paradrop_PublicAircraft", []]);
