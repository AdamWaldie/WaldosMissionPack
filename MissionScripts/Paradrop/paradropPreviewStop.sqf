/*
 * Author: WaldoTheWarfighter
 * Stops the live deployment-direction preview started by Waldo_fnc_ParadropPreviewStart: clears the
 * active flag (the installed Draw3D/KeyDown handlers are gated on it and are left installed, exactly
 * like Waldo_fnc_JammerMapDraw's single always-installed overlay handler) and dismisses the
 * instruction card. The last used heading is deliberately left in Waldo_Paradrop_PreviewDirection so
 * the next preview session on this client starts from where this one left off.
 *
 * Locality and authority: curator-client-local only.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_ParadropPreviewStop;
 *
 * Current callers: Waldo_fnc_ParadropPreviewStart's own Enter/Escape key handling.
 */

if (!hasInterface) exitWith {};
missionNamespace setVariable ["Waldo_Paradrop_PreviewActive", false];
["PARADROP_PREVIEW"] call Waldo_fnc_DismissUiNotification;
