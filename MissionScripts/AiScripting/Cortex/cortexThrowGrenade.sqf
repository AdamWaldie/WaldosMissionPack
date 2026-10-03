/*
 * Author: WaldoTheWarfighter
 * Makes one soldier throw a smoke or fragmentation grenade he is carrying, towards a position.
 *
 * Grenade types are identified from config, so mod grenades work: smoke is ammo simulation shotSmoke
 * or shotSmokeX; fragmentation is shotGrenade. Chemlights and ACE
 * flashbangs are skipped. The throw muzzle is the "Throw" weapon muzzle that accepts that magazine.
 * The thrower is turned to face the target and throws on the next frame, because a throw leaves
 * along the unit's facing. A fragmentation grenade is never thrown when a
 * friendly or civilian soldier is within 12 m of the target, or when the target is under 8 m or over
 * 40 m away. Engine AI already treat smoke particles as blocking sight.
 * Locality and authority: call where the unit is local (forceWeaponFire is local-argument).
 *
 * Repeat/JIP: next-frame execution rechecks ownership, medical/captivity status, Zeus takeover, drill replacement/cancellation, ammunition and frag safety;
 * A cancelled queued fragmentation throw records its drill token so assault may continue without it.
 * pending throws are not replayed to joining clients. Fragmentation throws track the actual projectile locally for assault sequencing; the temporary FiredMan handler removes itself or expires after ten seconds.
 * Arguments:
 * 0: unit <OBJECT>
 * 1: towards <ARRAY> - ATL position
 * 2: kind <STRING> - "SMOKE" or "FRAG" (optional, default: "SMOKE")
 *
 * Return Value:
 * Boolean - true when a carried grenade was queued; FiredMan/projectile evidence confirms deployment
 *
 * Example:
 * [_unit, _enemyPos, "FRAG"] call Waldo_fnc_CortexThrowGrenade;
 * Result: the lead assaulter throws a grenade before the final rush.
 *
 * Current callers: Waldo_fnc_CortexFlankStep and Waldo_fnc_CortexRetreat.
 */

params [["_unit", objNull, [objNull]], ["_towards", [], [[]]], ["_kind", "SMOKE", [""]]];
if (isNull _unit || {!alive _unit} || {!local _unit} || {vehicle _unit != _unit} || {count _towards < 2}) exitWith {false};
if !([_unit] call Waldo_fnc_CortexCombatEffective) exitWith {false};
_kind=toUpperANSI _kind;
if (!(_kind in ["SMOKE","FRAG"]) || {!([group _unit] call Waldo_fnc_CortexIsEligible)}) exitWith {false};
private _simulations = if (_kind == "FRAG") then {["shotGrenade"]} else {["shotSmoke", "shotSmokeX"]};
if (toUpperANSI _kind == "FRAG") then {
    private _distance = _unit distance2D _towards;
    private _side = side group _unit;
    if (_distance < 8 || {_distance > 40}) exitWith {_simulations = []};
    if ((_towards nearEntities ["CAManBase", 12]) findIf {
        private _otherSide = side group _x;
        alive _x && {_otherSide == civilian || {_side getFriend _otherSide >= 0.6}}
    } >= 0) then {_simulations = []};
};
if (_simulations isEqualTo []) exitWith {false};
private _throwConfig = configFile >> "CfgWeapons" >> "Throw";
private _muzzles = getArray (_throwConfig >> "muzzles");
private _thrown = false;
{
    private _magazine = _x;
    private _ammo = getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
    private _ammoConfig = configFile >> "CfgAmmo" >> _ammo;
    // Chemlights inherit from SmokeShell and ACE flashbangs use the grenade simulations: neither is
    // the smoke screen or fragmentation grenade the drill asked for.
    if (getText (_ammoConfig >> "simulation") in _simulations
        && {!(_ammo isKindOf ["Chemlight_base", configFile >> "CfgAmmo"])}
        && {getNumber (_ammoConfig >> "ace_grenades_flashbang") != 1}) then {
        private _muzzleIndex = _muzzles findIf {_magazine in getArray (_throwConfig >> _x >> "magazines")};
        if (_muzzleIndex >= 0) then {
            private _muzzle = _muzzles select _muzzleIndex;
            // A throw leaves along the unit's current facing, and doWatch turns him over several
            // frames, so face the target first and throw on the next frame.
            if (_kind == "FRAG") then {_unit setVariable ["Waldo_Cortex_FragCancelled",nil]};
            _unit setDir (_unit getDir _towards);
            _unit doWatch _towards;
            [{
                params ["_unit", "_muzzle", "_magazine", "_group", "_hold", "_kind", "_towards", "_drillToken"];
                private _cancel = {
                    if (_kind == "FRAG" && {_drillToken != ""}) then {
                        _unit setVariable ["Waldo_Cortex_FragCancelled",_drillToken];
                    };
                };
                if (!([_unit] call Waldo_fnc_CortexCombatEffective) || {!local _unit} || {vehicle _unit != _unit} || {group _unit != _group}
                    || {!([_group] call Waldo_fnc_CortexIsEligible)}
                    || {(_group getVariable ["Waldo_AIPass_ZeusHold",[]]) isNotEqualTo _hold}
                    || {!(_magazine in magazines _unit)}
                    || {(((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap]) getOrDefault ["token",""]) != _drillToken}) exitWith {call _cancel};
                if (_kind == "FRAG" && {_drillToken != ""}
                    && {!([_group,"Waldo_AIPass_Assault_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}) exitWith {call _cancel};
                if (_kind == "FRAG") then {
                    private _distance=_unit distance2D _towards;
                    private _side=side _group;
                    if (_distance < 8 || {_distance > 40} || {
                        (_towards nearEntities ["CAManBase",12]) findIf {
                            alive _x && {side group _x == civilian || {_side getFriend (side group _x) >= 0.6}}
                        } >= 0
                    }) exitWith {call _cancel};
                    private _old = _unit getVariable ["Waldo_Cortex_FragHandler",-1];
                    if (_old >= 0) then {_unit removeEventHandler ["FiredMan",_old]};
                    _unit setVariable ["Waldo_Cortex_FragFlight",[_drillToken,objNull,false,_magazine,-1]];
                    private _handler = _unit addEventHandler ["FiredMan",{
                        params ["_actor","_weapon","_muzzle","_mode","_ammo","_magazine","_projectile"];
                        private _flight = _actor getVariable ["Waldo_Cortex_FragFlight",[]];
                        if (_weapon == "Throw" && {count _flight == 5} && {_magazine == (_flight select 3)}) then {
                            _flight set [1,_projectile];
                            _flight set [2,true];
                            _flight set [4,time];
                            _actor removeEventHandler ["FiredMan",_thisEventHandler];
                            _actor setVariable ["Waldo_Cortex_FragHandler",-1];
                        };
                    }];
                    _unit setVariable ["Waldo_Cortex_FragHandler",_handler];
                    [{
                        params ["_actor","_handler"];
                        if ((_actor getVariable ["Waldo_Cortex_FragHandler",-1]) == _handler) then {
                            _actor removeEventHandler ["FiredMan",_handler];
                            _actor setVariable ["Waldo_Cortex_FragHandler",-1];
                        };
                    },[_unit,_handler],10] call CBA_fnc_waitAndExecute;
                    _unit forceWeaponFire [_muzzle,_muzzle];
                } else {_unit forceWeaponFire [_muzzle,_muzzle]};
            }, [_unit, _muzzle, _magazine, group _unit, +(group _unit getVariable ["Waldo_AIPass_ZeusHold",[]]), _kind, +_towards, (((group _unit) getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap]) getOrDefault ["token",""]]] call CBA_fnc_execNextFrame;
            _thrown = true;
        };
    };
    if (_thrown) exitWith {};
} forEach (magazines _unit);
_thrown
