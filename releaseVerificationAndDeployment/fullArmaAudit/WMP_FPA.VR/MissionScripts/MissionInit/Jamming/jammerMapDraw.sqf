/*
 * Author: WaldoTheWarfighter
 * Game-master overlay for the jamming system. Draws a floating icon and label above every active
 * jammer, plus its facing line for directional jammers, so a curator can see the electronic order
 * of battle in the world. Visible only to local curators (Zeus) - ordinary players never see it,
 * so it never leaks jammer positions. Registers a single Draw3D mission event handler that reads
 * the live registry each frame. Controlled by Waldo_Jamming_GmOverlay. Client-only, single instance.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_JammerMapDraw;
 */

if !(hasInterface) exitWith {};
if (missionNamespace getVariable ["Waldo_Jamming_OverlayRunning", false]) exitWith {};
missionNamespace setVariable ["Waldo_Jamming_OverlayRunning", true];

addMissionEventHandler ["Draw3D", {
    // Jammer locations are operational information, not a debugging aid that
    // should appear merely because a curator is present. Mission makers may
    // explicitly opt in by setting Waldo_Jamming_GmOverlay to true.
    private _showAll = missionNamespace getVariable ["Waldo_Jamming_GmOverlay", false];
    // Curators only.
    if (isNull (getAssignedCuratorLogic player)) exitWith {};

    private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
    {
        _x params ["_id", "_obj", "_radius", "_falloff", "_sides", "_bands", "_strength", "_active", "_mk", ["_sector", []], ["_duty", []], ["_jamUAV", false], ["_show3D", false]];
        if (!isNull _obj && {_showAll || {_show3D}}) then {
            private _col = if (_active) then { [0.85, 0.1, 0.15, 1] } else { [0.5, 0.5, 0.5, 0.8] };
            private _pos = getPosATL _obj;
            private _label = format ["JAMMER #%1  %2m  %3", _id, round _radius, (["OFF", "ON"] select (_active))];
            drawIcon3D [
                "\a3\ui_f\data\map\markers\military\dot_ca.paa",
                _col,
                [_pos select 0, _pos select 1, (_pos select 2) + 3],
                0.8, 0.8, 0,
                _label, 1, 0.03, "PuristaMedium"
            ];

            // Directional facing line.
            if (_sector isEqualType [] && {count _sector == 2} && {(_sector select 1) < 360}) then {
                private _bearing = _sector select 0;
                private _tip = _obj getPos [_radius, _bearing];
                drawLine3D [ASLToAGL (getPosASL _obj), [_tip select 0, _tip select 1, (getPosATL _obj) select 2], _col];
            };
        };
    } forEach _registry;
}];

diag_log "[WMP JAM] GM jammer overlay (Draw3D) installed.";
