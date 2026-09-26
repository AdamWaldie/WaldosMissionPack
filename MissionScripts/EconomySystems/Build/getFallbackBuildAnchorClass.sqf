/*
 * Author: WaldoTheWarfighter
 * Compatibility helper retained for old build-anchor calls; no placeholder is spawned.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <STRING> always "".
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_getFallbackBuildAnchorClass;
 * Locality/Authority: Any machine; constant compatibility result.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: No in-pack caller; retained for older mission scripts.
 * Result: Empty classname prevents a visually false fallback object.
 */

        // Kept as a compatibility function for mission code which may already
        // reference it. Buildables no longer receive a visually false object
        // when their configured class is missing or invalid.
        ""

