/*
 * Author: WaldoTheWarfighter
 * Lists the supported side keys for a delivery point.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <ARRAY of STRING> [ANY, WEST, EAST, GUER].
 *
 * Example:
 * [] call Waldo_fnc_EcoBuy_getDropPointSideChoices;
 * Locality/Authority: Any machine; constant selector data.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: Delivery-point authoring selectors.
 * Result: Supplies the accepted side choices in dialog order.
 */

        ["ANY", "WEST", "EAST", "GUER"]

