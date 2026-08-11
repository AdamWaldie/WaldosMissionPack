/*
 * Author: WaldoTheWarfighter
 * Installs the Obituary / confirmed-death reporting system: caches death info on every player
 * death, installs the medic-only "Pronounce Dead" ACE TARGET interaction (ACE_MainActions, NOT
 * ACE_SelfActions - confirmed intentional, this is an action performed on the corpse, not on
 * yourself; do not "fix" this to ACE_SelfActions later), and starts the local diary render loop.
 * Waits for the server-published feature config snapshot before reading Waldo_Obituary_Enable,
 * matching Waldo_fnc_TreatmentFeedbackInit's pattern, since interfaceConfig.sqf settings are not
 * guaranteed to have arrived the instant initPlayerLocal.sqf calls this.
 * Locality and authority: interface-client installer only; repeat-safe via Waldo_Obituary_Started.
 * The condition's `!(_target getVariable ["Waldo_Obituary_Complete", true])` default-true check
 * means a corpse that never got the variable at all - i.e. any AI kill, since
 * Waldo_fnc_ObituaryRecordDeath only writes it for isPlayer units - silently never shows the
 * action, with no separate isPlayer re-check needed.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when installed, already installed, or waiting on the config snapshot
 *
 * Example:
 * [] call Waldo_fnc_ObituaryInit;
 * Result: this client can see and use "Pronounce Dead" on eligible corpses when Medic-trait.
 * Current caller: initPlayerLocal.sqf, gated on Waldo_Obituary_Enable.
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", isServer]) exitWith {
    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
        };
        if (missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {[] call Waldo_fnc_ObituaryInit};
    };
    true
};
if !(missionNamespace getVariable ["Waldo_Obituary_Enable", true]) exitWith {false};
if !(isClass (configFile >> "CfgPatches" >> "ace_medical")) exitWith {false};
if !(isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) exitWith {false};
if (missionNamespace getVariable ["Waldo_Obituary_Started", false]) exitWith {true};
missionNamespace setVariable ["Waldo_Obituary_Started", true];

["CAManBase", "Killed", { [_this] call Waldo_fnc_ObituaryRecordDeath; }] call CBA_fnc_addClassEventHandler;

private _condition = {
    params ["_target", "_player"];
    !isNull _target && {!alive _target} && {alive _player} && {_player distance _target <= 3}
        && {_player getUnitTrait "Medic"} && {!(_target getVariable ["Waldo_Obituary_Complete", true])}
};
private _statement = { params ["_target", "_player"]; [_target, _player] call Waldo_fnc_ObituaryPronounce; };
private _action = ["Waldo_Obituary_Pronounce", "Pronounce Dead", "a3\ui_f\data\igui\cfg\actions\heal_ca.paa", _statement, _condition]
    call ace_interact_menu_fnc_createAction;
["CAManBase", 0, ["ACE_MainActions"], _action, true] call ace_interact_menu_fnc_addActionToClass;

[] call Waldo_fnc_ObituaryDiaryRenderLocal;
true
