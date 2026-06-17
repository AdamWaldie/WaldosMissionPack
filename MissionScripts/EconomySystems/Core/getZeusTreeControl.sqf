/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getZeusTreeControl
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getZeusTreeControl via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_disp", displayNull]];

    if (isNull _disp) then {
        _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
    };
    if (isNull _disp) exitWith {controlNull};

    private _tree = _disp displayCtrl 280;
    if !(isNull _tree) exitWith {_tree};

    private _treeCtrls = [];
    {
        if ((ctrlType _x) isEqualTo 12) then {
            _treeCtrls pushBack _x;
        };
    } forEach (allControls _disp);

    private _bestTree = controlNull;
    private _bestCount = -1;
    {
        private _rootCount = _x tvCount [];
        if (_rootCount > _bestCount) then {
            _bestCount = _rootCount;
            _bestTree = _x;
        };
    } forEach _treeCtrls;

    _bestTree
