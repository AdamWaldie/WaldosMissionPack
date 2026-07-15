/*
 * Author: Waldo
 * Register zeus menu injector.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Registers a per-client code block that injects one subsystem's menu into the Zeus
 * curator tree. Every active subsystem registers its own injector here instead of
 * spawning a private Zeus-open polling loop; a single shared detector loop
 * (Waldo_fnc_EcoCore_startZeusMenuHook) then runs every registered injector whenever the
 * curator display opens. Only subsystems that actually initialise register, so an
 * inactive subsystem contributes neither an injector nor a loop.
 *
 * Arguments:
 * 0: _injector <CODE> - injector run (spawned) on each Zeus-display open (optional, default: {})
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [{ ... inject my menu ... }] call Waldo_fnc_EcoCore_registerZeusMenuInjector;
 */

    params [["_injector", {}]];

    if (!hasInterface) exitWith {};
    if (!(_injector isEqualType {})) exitWith {};

    private _list = missionNamespace getVariable ["WaldoEcoCore_ZeusMenuInjectors", []];
    _list pushBack _injector;
    missionNamespace setVariable ["WaldoEcoCore_ZeusMenuInjectors", _list];

    [] call Waldo_fnc_EcoCore_startZeusMenuHook;
