/*
 * Author: WaldoTheWarfighter
 * Installs and boots the Waldos Mini Games engine on the machine that calls it.
 * Defines the full Waldo_MG_* runtime (engine config + core framework + every game),
 * runs it locally, and re-broadcasts it for JIP so late joiners install it too.
 * A per-machine version guard makes repeat calls a no-op, so it is safe to call
 * from init.sqf on every client and the server.
 *
 * Original engine: "Party Games Scripted" by |LorD|[Habilidade]Deus Ex.
 * Ported into WaldosMissionPack and rebranded to the Waldo_MG_ namespace; game
 * logic is preserved from the original composition. Do not claim original authorship.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_MiniGamesInit;
 */

private _runtime = {

private _wmgCompositionHost = if (isNil "this") then {objNull} else {this};
private _wmgStoredHost = missionNamespace getVariable ["Waldo_MG_CompositionHostObject", objNull];
if (!isNull _wmgCompositionHost) then {
    missionNamespace setVariable ["Waldo_MG_CompositionHostObject", _wmgCompositionHost];
    if (local _wmgCompositionHost) then {
        _wmgCompositionHost allowDamage false;
    };
    _wmgCompositionHost setVariable ["Waldo_MG_CompositionSeed", true, true];
} else {
    if (isNull _wmgStoredHost) then {
        missionNamespace setVariable ["Waldo_MG_CompositionHostObject", objNull];
    };
};

Waldo_MG_Version = "1.6.0";

private _wmgRuntimeKey = missionNamespace getVariable ["Waldo_MG_RuntimeKeyLocal", []];
private _wmgRuntimeVersion = _wmgRuntimeKey param [0, ""];
private _wmgRuntimeHost = _wmgRuntimeKey param [1, objNull];
private _wmgDuplicateRuntime = (_wmgRuntimeVersion == Waldo_MG_Version) && {
    isNull _wmgCompositionHost || {_wmgRuntimeHost == _wmgCompositionHost}
};
if (_wmgDuplicateRuntime) exitWith {};
missionNamespace setVariable ["Waldo_MG_RuntimeKeyLocal", [Waldo_MG_Version, _wmgCompositionHost]];


    #include "engine\config.sqf"
    #include "engine\core.sqf"
    #include "engine\games\battleship.sqf"
    #include "engine\games\blackjack.sqf"
    #include "engine\games\checkers.sqf"
    #include "engine\games\chess.sqf"
    #include "engine\games\poker.sqf"
    #include "engine\games\drawpoker.sqf"
    #include "engine\games\liarsdice.sqf"
    #include "engine\games\connectfour.sqf"
    #include "engine\games\rps.sqf"
    #include "engine\games\shotgun.sqf"
    #include "engine\games\uno.sqf"
    #include "engine\games\whoswho.sqf"

    call Waldo_MG_fnc_bootstrap;
};

[] call _runtime;

if (isMultiplayer) then {
    [[], _runtime] remoteExec ["spawn", 0, "Waldo_MG_Runtime_JIP"];
};
