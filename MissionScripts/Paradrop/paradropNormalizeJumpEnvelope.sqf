/*
 * Author: WaldoTheWarfighter
 * Clamps a static-line/HALO jump envelope so it is always reachable at a given route altitude and
 * speed - the concrete fix for a paradrop plane whose jump action never becomes available because
 * its flight altitude/speed don't actually satisfy the configured Waldo_fnc_AddStaticJump /
 * Waldo_fnc_AddHaloJump conditions (see those functions: the hold action's condition checks the
 * aircraft's live altitude against min/max and its speed against max, every frame it's offered).
 * Setting a route altitude and a jump envelope independently is exactly how that mismatch happens;
 * this function is the one place both paradrop entry points make sure it can't.
 *
 * Arguments:
 * 0: route altitude <NUMBER> - metres AGL the aircraft will actually fly at.
 * 1: route maximum speed <NUMBER> - km/h the aircraft will actually be capped to.
 * 2: requested static-line minimum altitude <NUMBER> (raw mission-maker/default value).
 * 3: requested static-line maximum altitude <NUMBER> (raw mission-maker/default value).
 * 4: requested static-line maximum speed <NUMBER> (raw mission-maker/default value).
 * 5: requested HALO minimum altitude <NUMBER> (raw mission-maker/default value).
 *
 * Return Value:
 * HashMap - staticMinimumAltitude, staticMaximumAltitude, staticMaximumSpeed, haloMinimumAltitude,
 * each guaranteed satisfiable at the supplied route altitude/speed:
 * - staticMinimumAltitude never exceeds route altitude - 25 m (a static-line jumper must be able to
 *   release at least 25 m below the route's cruise altitude).
 * - staticMaximumAltitude never falls below route altitude + 75 m (route altitude must sit inside
 *   the static-line window with headroom, not right at its edge).
 * - staticMaximumSpeed never falls below route speed + 40 km/h (the aircraft's actual cruise speed
 *   must stay comfortably under the jump's speed ceiling, not brush against it).
 * - haloMinimumAltitude never exceeds route altitude (HALO release must be reachable at cruise
 *   altitude, not above it).
 *
 * Example:
 * [250, 220, 180, 350, 310, 1000] call Waldo_fnc_ParadropNormalizeJumpEnvelope;
 *
 * Current callers: Waldo_fnc_ParadropCreateDropZone, Waldo_fnc_ParadropQuickFlightSetup.
 */

params [
    ["_altitude", 250, [0]],
    ["_maxSpeed", 220, [0]],
    ["_rawStaticMin", 180, [0]],
    ["_rawStaticMax", 350, [0]],
    ["_rawStaticMaxSpeed", 310, [0]],
    ["_rawHaloMin", 1000, [0]]
];

createHashMapFromArray [
    ["staticMinimumAltitude", (_rawStaticMin max 0) min ((_altitude - 25) max 0)],
    ["staticMaximumAltitude", (_rawStaticMax max (_altitude + 75)) min 2500],
    ["staticMaximumSpeed", (_rawStaticMaxSpeed max (_maxSpeed + 40)) min 700],
    ["haloMinimumAltitude", (_rawHaloMin max 0) min _altitude]
]
