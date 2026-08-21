/*
 * Author: WaldoTheWarfighter
 * Installs the single interface-local Draw3D renderer for every WMP custom world marker. Object
 * offsets are interpreted in that object's model space: X is sideways, Y is forwards and Z is up.
 * Fixed-position offsets remain world east/north/up. DrawIcon3D requires PositionAGL, so this
 * renderer deliberately uses modelToWorldVisual for objects and keeps fixed ATL anchors in AGL.
 * Do not replace either path with an ASL/world conversion: terrain elevation would then be added
 * to the displayed height and an on-object marker would appear far above its target. Each client
 * requests one revisioned server snapshot after installing; later changes arrive as compact
 * deltas. This repeat-safe installer creates only one event handler per interface machine.
 *
 * Arguments: None.
 * Return Value: Boolean - true when installed/already installed; false without an interface.
 * Current caller: initPlayerLocal.sqf during player UI setup.
 * Example: [] call Waldo_fnc_Init3DMarkers;
 */
if (!hasInterface) exitWith {false};
if ((missionNamespace getVariable ["Waldo_3DMarker_DrawHandler", -1]) >= 0) exitWith {true};
if (!isServer) then {
    missionNamespace setVariable ["Waldo_3DMarker_Registry", []];
    missionNamespace setVariable ["Waldo_3DMarker_Revision", -1];
};
private _handler = addMissionEventHandler ["Draw3D", {
    private _playerSide = toUpper str side group player;
    {
        _x params [
            "_id", "_anchor", "_offset", "_icon", "_colour", "_width", "_height",
            "_angle", "_text", "_shadow", "_textSize", "_font", "_align",
            "_sideArrows", "_maxDistance", "_sides", "_enabled"
        ];
        if (_enabled) then {
            private _position = if (_anchor isEqualType objNull) then {
                if (isNull _anchor) then {[]} else {_anchor modelToWorldVisual _offset}
            } else {
                (_anchor select [0, 3]) vectorAdd _offset
            };
            private _sideNames = _sides apply {if (_x isEqualType "") then {toUpper _x} else {toUpper str _x}};
            private _sideVisible = "ALL" in _sideNames || {_playerSide in _sideNames};
            if (_sideVisible && {!(_position isEqualTo [])} && {player distance2D _position <= _maxDistance}) then {
                drawIcon3D [_icon, _colour, _position, _width, _height, _angle, _text, _shadow, _textSize, _font, _align, _sideArrows];
            };
        };
    } forEach (missionNamespace getVariable ["Waldo_3DMarker_Registry", []]);
}];
missionNamespace setVariable ["Waldo_3DMarker_DrawHandler", _handler];
if (!isServer) then {[] call Waldo_fnc_Marker3DRequestStateServer};
true
