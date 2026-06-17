/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getNearestMarkerColor
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getNearestMarkerColor via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_hex", "#FFFFFF"]];

    private _safe = [_hex] call Waldo_fnc_EcoResource_normalizeResourceColor;
    private _r = parseNumber ("0x" + (_safe select [1, 2]));
    private _g = parseNumber ("0x" + (_safe select [3, 2]));
    private _b = parseNumber ("0x" + (_safe select [5, 2]));

    private _palette = [
        ["ColorBlack", [0, 0, 0]],
        ["ColorGrey", [128, 128, 128]],
        ["ColorRed", [255, 0, 0]],
        ["ColorBrown", [128, 64, 0]],
        ["ColorOrange", [255, 128, 0]],
        ["ColorYellow", [255, 255, 0]],
        ["ColorKhaki", [195, 176, 145]],
        ["ColorGreen", [0, 160, 0]],
        ["ColorBlue", [0, 96, 255]],
        ["ColorPink", [255, 105, 180]],
        ["ColorWhite", [255, 255, 255]]
    ];

    private _bestName = "ColorWhite";
    private _bestDistance = 1e12;

    {
        private _rgb = _x param [1, [255, 255, 255]];
        private _distance =
            ((_r - (_rgb select 0)) ^ 2) +
            ((_g - (_rgb select 1)) ^ 2) +
            ((_b - (_rgb select 2)) ^ 2);

        if (_distance < _bestDistance) then {
            _bestDistance = _distance;
            _bestName = _x param [0, "ColorWhite"];
        };
    } forEach _palette;

    _bestName
