/*
 * Author: WaldoTheWarfighter
 * Populates a starter crate, optionally adds limited or unrestricted Arsenal access, and installs
 * the local save-loadout interaction for current and joining players.
 *
 * Locality/authority: safe from an Eden object init on every machine; only the server mutates cargo
 * and publishes setup. A listen host applies its own local action directly.
 * Repeat/JIP behaviour: local action setup is repeat-safe. Its named JIP entry is bound to the crate
 * and removed from the engine queue when the crate is deleted.
 *
 * Arguments: crate OBJECT; arsenal BOOL; equipment side SIDE (default west); unrestricted BOOL
 * (default false).
 * Return Value: Nothing; intended for spawned use because it waits for mission setup readiness.
 * Current callers: mission-maker starter-crate object init fields.
 * Example: [this, true, west, false] spawn Waldo_fnc_DoStarterCrate;
 */
params["_target","_arsenal",["_crateSide",west],["_unrestrictedArsenal",false]];
// Public editor call: every machine may execute an object's init field, but the server owns all
// global inventory mutations and publishes the client-local actions for hosted, dedicated and JIP.
if (!isServer) exitWith {};

//Wait Until Init is completed & players ingame (Postinit hack)
waitUntil { missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] };
//Double Security with ensuring mission.sqm sweep
waitUntil { missionNamespace getVariable ["Logi_MissionScanComplete", false] };


// Preserve the original blue identifier and install the functional save interaction on every
// current interface. The keyed replay gives later joiners the same local actions.
if (hasInterface) then {[_target] call Waldo_fnc_StarterCrateSetupLocal};
private _starterJipId = format ["Waldo_StarterCrate_%1", netId _target];
[_target] remoteExecCall ["Waldo_fnc_StarterCrateSetupLocal", -2, _starterJipId];
[_target, _starterJipId] call Waldo_fnc_JipBindToObjectServer;


//Add full compliment of supplies (MEDICAL NOTWITHSTANDING)
[_target, 1,_crateSide, false, false] call Waldo_fnc_SupplyCratePopulate;

if (_arsenal == true) then {
    if (_unrestrictedArsenal == true) then {
        //Vanilla Arsenal & ACE Arsenal
        ["AmmoboxInit",[_target,true]] call BIS_fnc_arsenal;
        [_target, true] call ace_arsenal_fnc_initBox;
    } else {
        //Add Limited Ace Arsenal 
        [_target,_crateSide,false] call Waldo_fnc_CreateLimitedArsenal;
    };
};
