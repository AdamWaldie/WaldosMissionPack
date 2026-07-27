/* Installs the single local renderer for custom WMP 3D markers. */
if (!hasInterface) exitWith {false};
if ((missionNamespace getVariable ["Waldo_3DMarker_DrawHandler", -1]) >= 0) exitWith {true};
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
                if (isNull _anchor) then {[]} else {(visiblePositionASL _anchor) vectorAdd _offset}
            } else {
                AGLToASL ((_anchor select [0, 3]) vectorAdd _offset)
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
true
