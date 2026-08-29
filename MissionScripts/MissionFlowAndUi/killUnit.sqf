/*
 * Author: WaldoTheWarfighter
 * Force-kills a unit or destroys a vehicle immediately, regardless of ACE medical state or a prior
 * `allowDamage false` - the scripted equivalent of the vanilla Zeus END-key kill shortcut, which a
 * later Arma engine update changed to respect `allowDamage`: any unit/object a mission (or WMP itself
 * - SafeStart and ENDEX both disable damage while active) had made damage-immune stopped dying to it.
 * `allowDamage true` is force-set on the target first so this always lands regardless of that state
 * (ACE's own setDead does the same internally for a person, but the plain setDamage 1 fallback below
 * does not, so this is done unconditionally up front rather than relied on per-branch).
 * A living ACE-medical person is then killed through `ace_medical_status_fnc_setDead` - confirmed
 * against ACE's own source: this is an internal function (its own header marks it "Public: No", so
 * ACE gives no compatibility guarantee on it across versions), but it is the standard technique the
 * Arma scripting community uses for a medical-aware forced kill, since ACE ships no public equivalent
 * and a bare setDamage/setHit routinely fails to actually kill a unit under ACE Advanced Medical
 * (it critically wounds instead). Going through it means unconscious/bleedout state, revive
 * eligibility and the Obituary/AAR kill-count hooks all resolve exactly as a real death would; every
 * other case (no ACE medical loaded, a vehicle, a non-ACE AI unit) falls back to a plain
 * `setDamage 1`, which still fires the same "Killed"/EntityKilled event handlers everything else in
 * the pack (Obituary, AAR) already listens on.
 * Server-authoritative; self-forwards to the server when called on a client, the same convention
 * Waldo_fnc_Jammer and Waldo_fnc_EMP already use, so it is safe to call directly from a script,
 * trigger, or an object's own Eden init field with no isServer wrapper.
 *
 * Arguments:
 * 0: _target - OBJECT - the unit or vehicle to kill/destroy
 *
 * Return Value:
 * BOOLEAN - true if a kill was applied (false if the target was already dead/null, or on a client
 * before the request reaches the server)
 *
 * Example:
 * [cursorTarget] call Waldo_fnc_KillUnit;
 */

params [["_target", objNull, [objNull]]];

if !(isServer) exitWith {
    [_target] remoteExecCall ["Waldo_fnc_KillUnit", 2];
    false
};

if (isNull _target || {!alive _target}) exitWith {false};

// Restore damage eligibility first - this is the exact condition the engine change added: a target
// with allowDamage false no longer dies to setDamage/setDead at all, it just silently no-ops.
_target allowDamage true;

if (isClass (configFile >> "CfgPatches" >> "ace_medical") && {_target isKindOf "CAManBase"}) then {
    // Real signature confirmed against ACE's own source: [unit, reason <STRING>, source, instigator].
    [_target, "WMP_KillUnit", objNull, objNull] call ace_medical_status_fnc_setDead;
} else {
    _target setDamage 1;
};

// A small number of edge cases (ACE full-heal race, a mod's own damage-handling EH) can leave a
// target that was hit with setDead/setDamage 1 still reporting alive on the very next frame; a
// second, harder setDamage clears that instead of silently reporting success on a unit still standing.
if (alive _target) then {
    _target setDamage 1;
};

!(alive _target)
