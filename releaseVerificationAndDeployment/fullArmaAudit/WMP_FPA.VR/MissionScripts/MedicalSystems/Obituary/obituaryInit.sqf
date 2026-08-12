/*
 * Author: WaldoTheWarfighter
 * Installs the Obituary / confirmed-death reporting system: caches death info on every player
 * death, installs the medic-only "Pronounce Dead" ACE_SelfActions submenu
 * (Waldo_fnc_ObituarySelfInteractionInit) rather than a per-corpse ACE_MainActions target action, and
 * starts the local diary render loop. The self-action opens onto a dynamically built list of every
 * eligible corpse within Waldo_Obituary_Radius (Waldo_fnc_ObituaryChildrenLocal) so a medic
 * acknowledges each casualty individually instead of needing to stand within 3m of, and look directly
 * at, one exact body - see that function's header for why this replaces the earlier target-action
 * design.
 * Waits for the server-published feature config snapshot before reading Waldo_Obituary_Enable,
 * matching Waldo_fnc_TreatmentFeedbackInit's pattern, since interfaceConfig.sqf settings are not
 * guaranteed to have arrived the instant initPlayerLocal.sqf calls this.
 * Locality and authority: interface-client installer only; the one-time parts (Killed handler, diary
 * render loop) are repeat-safe via Waldo_Obituary_Started, and the self-action install is repeat-safe
 * (and respawn-safe) via Waldo_fnc_ObituarySelfInteractionInit's own guard.
 * The child list's `!(_target getVariable ["Waldo_Obituary_Complete", true])` default-true check
 * means a corpse that never got the variable at all - i.e. any AI kill, since
 * Waldo_fnc_ObituaryRecordDeath only writes it for isPlayer units - silently never appears in the
 * list, with no separate isPlayer re-check needed.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when installed, already installed, or waiting on the config snapshot
 *
 * Example:
 * [] call Waldo_fnc_ObituaryInit;
 * Result: this client can see and use "Pronounce Dead" on eligible nearby corpses when Medic-trait.
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

if !(missionNamespace getVariable ["Waldo_Obituary_Started", false]) then {
    missionNamespace setVariable ["Waldo_Obituary_Started", true];
    ["CAManBase", "Killed", { [_this] call Waldo_fnc_ObituaryRecordDeath; }] call CBA_fnc_addClassEventHandler;
    [] call Waldo_fnc_ObituaryDiaryRenderLocal;
};

[] call Waldo_fnc_ObituarySelfInteractionInit;
true
