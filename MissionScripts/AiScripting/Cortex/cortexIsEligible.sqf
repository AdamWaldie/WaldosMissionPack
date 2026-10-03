/*
 * Author: WaldoTheWarfighter
 * Decides whether the Smart AI Pass may command a group. This is the single exclusion gate for
 * every pass behaviour, so a new behaviour never needs its own list of other WMP features.
 *
 * A group is refused when:
 * - it contains a living player, or its side is not in Waldo_AIPass_IncludedSides;
 * - the group or any living member sets Waldo_AI_Exclude (all WMP AI changes) or
 *   Waldo_AIPass_Exclude (this pass only);
 * - the group, a member, or a member's current or assigned vehicle belongs to another WMP feature:
 *   Waldo_ServerOwnedFeature (Headless pin: Gunship, AI Convoy, Dynamic AA, Paradrop aircraft and
 *   jumpers), Gunship, Transport Services, Paradrop drop zones, Dynamic AA systems, pinned
 *   helicopters during an active WMP landing correction, or a dialogue speaker. The permanent
 *   helicopter locality pin alone is not behavioural ownership; otherwise every ordinary helicopter
 *   would be excluded from Cortex attack patterns and defensive reactions. Landed paratroopers and the dismounted crew of a written-off
 *   transport are un-pinned by Waldo_fnc_CortexReleaseFeatureCrew and then pass this check;
 * - a member uses a UAV or UGV (for example Virtual Vehicle Depot drone crews);
 * - Zeus has priority: the group is held after a curator edited it or gave it waypoints
 *   (Waldo_fnc_CortexZeusHeld), a member is remote-controlled (vanilla and ZEN both set
 *   bis_fnc_moduleRemoteControl_owner), or a member is under a ZEN AI order (ZEN garrison or ZEN
 *   suppressive fire);
 * - a member fails the shared AI filters: Waldo_AI_IncludedFactions, Waldo_AI_ExcludedFactions or
 *   Waldo_AI_ExcludedClasses.
 * - WebKnight custom AI owns the actor, IMS currently owns its melee state, or Simple Civilian
 *   Behaviour owns an unarmed civilian. Addon presence alone never excludes ordinary infantry.
 * Dynamic AO groups are deliberately eligible. Waldo_Headless_ExcludeGroup only pins locality and
 * does not exclude a group from behaviour.
 *
 * Locality and authority: read-only and callable anywhere; it changes and broadcasts nothing.
 *
 * Review contract: Feature markers are checked on the group as well as members and vehicles. Zeus-held checks maintain the documented local timing cache and may clear an expired waypoint flag.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: ignore temporary Zeus hold <BOOL>, default false; explicit order preflight only.
 * 2: generic ground pass <BOOL>, default false. When true, any group with a living member aboard
 *    an aircraft is reserved for the dedicated airborne, flare and attack controllers. This keeps
 *    infantry contact, support, regroup and vehicle-ground logic from competing for its pilot.
 * Repeat/JIP: read-only apart from the documented local hold cache; safe to repeat.
 *
 * Return Value:
 * Boolean - true when the pass may command the group
 *
 * Example:
 * [group _unit] call Waldo_fnc_CortexIsEligible;
 * Result: false for a player squad, a gunship crew or any group marked with Waldo_AIPass_Exclude.
 *
 * Current callers: shared eligibility gates across Cortex group, vehicle, aircraft, artillery,
 * building, support and locality controllers.
 */

params [["_group", grpNull, [grpNull]], ["_ignoreZeusHold",false,[true]], ["_groundPass",false,[true]]];
if (isNull _group) exitWith {false};
if (_group getVariable ["Waldo_AI_ExternalControl", false] || {"ALL" in (_group getVariable ["Waldo_AIPass_DisabledFeatures", []])}) exitWith {false};
// Zeus always has priority: a group Zeus is commanding is left alone (Waldo_fnc_CortexZeusHeld).
if (!_ignoreZeusHold && {[_group] call Waldo_fnc_CortexZeusHeld}) exitWith {false};
if (_group getVariable ["Waldo_AI_Exclude", false]
    || {_group getVariable ["Waldo_AIPass_Exclude", false]}
    || {_group getVariable ["Waldo_ServerOwnedFeature", false]}) exitWith {false};

private _alive = (units _group) select {alive _x};
if (_alive isEqualTo [] || {_alive findIf {isPlayer _x} >= 0}) exitWith {false};
if (_groundPass && {_alive findIf {
    private _vehicle=vehicle _x;
    _vehicle != _x && {_vehicle isKindOf "Air"}
} >= 0}) exitWith {false};

if (_alive findIf {
    private _job = _x getVariable ["Waldo_Convoy_Dismount", []];
    count _job == 4 && {serverTime < (_job select 2)}
} >= 0) exitWith {false};
private _sideKey = switch (side _group) do {
    case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; case civilian: {"CIV"}; default {""};
};
private _includedSides = ((missionNamespace getVariable ["Waldo_AIPass_IncludedSides", ["WEST", "EAST", "GUER"]]) select {_x isEqualType ""}) apply {toUpperANSI _x};
if !(_sideKey in _includedSides) exitWith {false};

private _includedFactions = missionNamespace getVariable ["Waldo_AI_IncludedFactions", []];
private _excludedFactions = missionNamespace getVariable ["Waldo_AI_ExcludedFactions", []];
private _excludedClasses = missionNamespace getVariable ["Waldo_AI_ExcludedClasses", []];
// Presence of any of these values means another WMP feature owns the object's behaviour.
private _featureMarkers = [
    "Waldo_Convoy_Active", "Waldo_ServerOwnedFeature", "Waldo_Gunship_Id", "Waldo_TransportService_Registered",
    "Waldo_Paradrop_DropZoneId", "Waldo_DynamicAA_SystemId"
];
private _isFeatureOwned = {
    params ["_object"];
    _featureMarkers findIf {
        private _value = _object getVariable _x;
        !isNil "_value" && {!(_value isEqualTo false)}
    } >= 0
};

if ([_group] call _isFeatureOwned) exitWith {false};

(_alive findIf {
    private _unit = _x;
    private _vehicles = [vehicle _unit, assignedVehicle _unit] select {!isNull _x && {_x != _unit}};
    (_unit getVariable ["Waldo_AI_Exclude", false])
    || {_unit getVariable ["Waldo_AIPass_Exclude", false]}
    || {_unit getVariable ["Waldo_Dialogue_Available", false]}
    || {_unit getVariable ["Waldo_Dialogue_Occupied", false]}
    || {!isNull (_unit getVariable ["bis_fnc_moduleRemoteControl_owner", objNull])}
    || {_unit getVariable ["zen_ai_garrisoned", false]}
    || {_unit getVariable ["zen_ai_isSuppressing", false]}
    || {[_unit] call Waldo_fnc_CortexExternalOwner != ""}
    || {[_unit] call _isFeatureOwned}
    || {count _includedFactions > 0 && {!(faction _unit in _includedFactions)}}
    || {faction _unit in _excludedFactions}
    || {typeOf _unit in _excludedClasses}
    // The permanent helicopter pin prevents unstable HC transfer; it does not own flight behaviour.
    // Only an active landing correction excludes the operating crew. A separate cargo squad remains
    // eligible for an explicit airborne order throughout.
    || {_vehicles findIf {_x getVariable ["Waldo_ImprovedHelicopterLanding_Active",false] && {group driver _x == _group}} >= 0}
    || {_vehicles findIf {unitIsUAV _x || {[_x] call _isFeatureOwned}} >= 0}
}) < 0
