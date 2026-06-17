/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - setPromptInputTargets
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_setPromptInputTargets via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull], ["_targets", []], ["_focusCtrl", controlNull]];
        [_disp, _targets, _focusCtrl, "WaldoEcoResearch_InputTargets", [14, 28, 156, 211]] call Waldo_fnc_EcoCore_setPromptInputTargets;

