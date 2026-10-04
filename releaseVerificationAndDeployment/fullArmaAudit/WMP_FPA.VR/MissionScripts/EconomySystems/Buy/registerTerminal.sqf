/*
 * Author: WaldoTheWarfighter (Waldos Economy Systems)
 * Designates an existing, editor-placed object as a Purchase Terminal (Buy system), so a
 * mission maker can set up the economy in Eden instead of spawning everything live in Zeus.
 *
 * Place a "Land_Laptop_unfolded_F" object in Eden and put this in its init field:
 *     [this] call Waldo_fnc_EcoBuy_registerTerminal;
 *
 * The economy suite must be enabled in MissionConfig (or by an Economy composition).
 * JIP-safe: the tag is broadcast and the per-machine action loop maintains the interaction
 * for joining/rejoining players. Must be a Land_Laptop_unfolded_F (the class the loop tracks).
 *
 * Arguments:
 * 0: _object - OBJECT - the placed purchase-terminal object (this)
 *
 * Return Value:
 * Nothing
 * Locality/Authority: Eden object init can run on each machine. Economy authority publishes
 * the terminal tag; interface clients install local actions.
 * Repeat/JIP Behaviour: Registration and local action installation are repeat-safe; joining
 * clients discover the published terminal tag and install their own interaction.
 * Current Callers: Eden object init fields and Economy composition setup.
 * Example: [this] call Waldo_fnc_EcoBuy_registerTerminal;
 * Result: The placed laptop becomes a usable Purchase Terminal.
 */

params ["_object"];
if (isNull _object) exitWith {};

if ([] call Waldo_fnc_EcoCore_canRunAuthority) then {
    _object setVariable ["WaldoEcoBuy_IsPurchaseTerminal", true, true];
    [_object, "PURCHASE_TERMINALS"] call Waldo_fnc_EcoCore_registerRuntimeObject;
    [_object, true] call Waldo_fnc_EcoResource_registerCuratorEditableObject;
};

if (hasInterface) then {
    [_object] call Waldo_fnc_EcoBuy_ensurePurchaseTerminalActionLocal;
};
