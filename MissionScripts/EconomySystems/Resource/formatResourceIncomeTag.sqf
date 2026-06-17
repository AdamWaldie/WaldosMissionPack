/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - formatResourceIncomeTag
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_formatResourceIncomeTag via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_ratePerMinute", 0]];

    private _rate = _ratePerMinute;
    if (abs _rate < 0.05) then {
        _rate = 0;
    };

    private _color = "#FFFFFF";
    if (_rate > 0) then {_color = "#55FF55";};
    if (_rate < 0) then {_color = "#FF5555";};

    private _absRate = abs _rate;
    private _valueText = if (abs (_absRate - round _absRate) < 0.05) then {
        str (round _absRate)
    } else {
        _absRate toFixed 1
    };

    format [
        " <t color='%1'>(%2%3/min)</t>",
        _color,
        ["+", "-"] select (_rate < 0),
        _valueText
    ]
