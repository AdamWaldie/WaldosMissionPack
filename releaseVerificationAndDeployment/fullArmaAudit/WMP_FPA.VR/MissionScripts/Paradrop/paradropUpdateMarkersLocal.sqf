/*
 * Author: WaldoTheWarfighter
 * Updates all local paradrop aircraft marker positions from local object state.
 *
 * Companion tick to Waldo_fnc_ParadropSetupLocal, mirroring how
 * Waldo_fnc_GunshipUpdateMarkersLocal keeps the airborne gunship aircraft marker live - same
 * per-frame position/heading refresh, same friendly-side visibility test, same reliance on the
 * marker normally created by Waldo_fnc_ParadropSetupLocal. Network state and the remote setup call
 * can arrive in either order, so this updater also creates any missing marker once the broadcast
 * aircraft entry becomes visible. That self-healing path is required for dedicated/JIP clients.
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
    // Own-side only, not merely "friendly" - matches Waldo_fnc_ParadropSetupLocal's own gate.
    private _visible = !isNull _aircraft && {alive _aircraft} && {side group player == _side};
    if (_visible) then {
        private _markerName = format ["Waldo_Paradrop_%1_Aircraft", _id];
        if (markerShape _markerName == "") then {
            createMarkerLocal [_markerName, getPosWorld _aircraft];
            _markerName setMarkerTypeLocal "b_plane";
            _markerName setMarkerColorLocal (switch (_side) do {
                case east: {"ColorOPFOR"};
                case independent: {"ColorIndependent"};
                case civilian: {"ColorCivilian"};
                default {"ColorBLUFOR"};
            });
            diag_log format ["[WMP PARADROP] Reconciled live aircraft marker id=%1 aircraft=%2 side=%3.", _id, netId _aircraft, _side];
        };
        _markerName setMarkerPosLocal getPosWorld _aircraft;
        _markerName setMarkerDirLocal getDir _aircraft;
        _markerName setMarkerTextLocal _name;
    };
} forEach (missionNamespace getVariable ["Waldo_Paradrop_PublicAircraft", []]);
