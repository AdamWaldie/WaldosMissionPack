/*
 * Author: WaldoTheWarfighter
 * Loads the interaction-equipment functions required by the disposable no-BattlEye QA mission.
 * The scripted-mission bootstrap avoids dependency on the user's profile, scenario browser, mods
 * or a saved Eden mission and explicitly registers every transitive UI dependency.
 *
 * Arguments: None.
 * Return Value: Nothing.
 *
 * Example: [] execVM "scriptedBootstrap.sqf";
 * Current caller: launch_interaction_ui_qa.ps1 through playScriptedMission.
 */
private _root = missionNamespace getVariable ["Waldo_MG_QA_Root", ""];
if (_root == "") exitWith {diag_log "WMP INTERACTION UI QA: bootstrap root missing";};
private _functions = [
    ["Waldo_fnc_UiColourVisionProfile", "MissionScripts\MissionFlowAndUi\Accessibility\uiColourVisionProfile.sqf"],
    ["Waldo_fnc_UiTheme", "MissionScripts\MissionFlowAndUi\uiTheme.sqf"],
    ["Waldo_fnc_RegisterUiReservationLocal", "MissionScripts\MissionFlowAndUi\registerUiReservationLocal.sqf"],
    ["Waldo_fnc_UnregisterUiReservationLocal", "MissionScripts\MissionFlowAndUi\unregisterUiReservationLocal.sqf"],
    ["Waldo_fnc_ReflowUiPanels", "MissionScripts\MissionFlowAndUi\reflowUiPanels.sqf"],
    ["Waldo_fnc_DialogueShowLineLocal", "MissionScripts\MissionFlowAndUi\Dialogue\Simple\dialogueShowLineLocal.sqf"],
    ["Waldo_fnc_DialogueHideLocal", "MissionScripts\MissionFlowAndUi\Dialogue\Simple\dialogueHideLocal.sqf"],
    ["Waldo_fnc_ConversationShowChoicesLocal", "MissionScripts\MissionFlowAndUi\Dialogue\Advanced\conversationShowChoicesLocal.sqf"],
    ["Waldo_fnc_ConversationHideChoicesLocal", "MissionScripts\MissionFlowAndUi\Dialogue\Advanced\conversationHideChoicesLocal.sqf"],
    ["Waldo_fnc_ConversationChooseServer", "MissionScripts\MissionFlowAndUi\Dialogue\Advanced\conversationChooseServer.sqf"],
    ["Waldo_fnc_ConversationCancel", "MissionScripts\MissionFlowAndUi\Dialogue\Advanced\conversationCancel.sqf"],
    ["Waldo_fnc_MiniGameRegisterChallenge", "MissionScripts\InteractionsMinigames\Core\registerChallenge.sqf"],
    ["Waldo_fnc_MiniGameChallengeResolve", "MissionScripts\InteractionsMinigames\Core\miniGameChallengeResolve.sqf"],
    ["Waldo_fnc_MiniGameEquipmentRect", "MissionScripts\InteractionsMinigames\Core\equipmentRect.sqf"],
    ["Waldo_fnc_MiniGameEquipmentCreateControl", "MissionScripts\InteractionsMinigames\Core\equipmentCreateControl.sqf"],
    ["Waldo_fnc_MiniGameEquipmentSetPosition", "MissionScripts\InteractionsMinigames\Core\equipmentSetPosition.sqf"],
    ["Waldo_fnc_MiniGameEquipmentPolyline", "MissionScripts\InteractionsMinigames\Core\equipmentPolyline.sqf"],
    ["Waldo_fnc_MiniGameEquipmentFitText", "MissionScripts\InteractionsMinigames\Core\equipmentFitText.sqf"],
    ["Waldo_fnc_MiniGameEquipmentFitStructuredText", "MissionScripts\InteractionsMinigames\Core\equipmentFitStructuredText.sqf"],
    ["Waldo_fnc_MiniGameEquipmentBindDrag", "MissionScripts\InteractionsMinigames\Core\equipmentBindDrag.sqf"],
    ["Waldo_fnc_MiniGameEquipmentAddDisplayHandler", "MissionScripts\InteractionsMinigames\Core\equipmentAddDisplayHandler.sqf"],
    ["Waldo_fnc_MiniGameEquipmentCleanup", "MissionScripts\InteractionsMinigames\Core\equipmentCleanup.sqf"],
    ["Waldo_fnc_MiniGameEquipmentValidateDisplay", "MissionScripts\InteractionsMinigames\Core\equipmentValidateDisplay.sqf"],
    ["Waldo_fnc_MiniGameEquipmentPreviewState", "MissionScripts\InteractionsMinigames\Core\equipmentPreviewState.sqf"],
    ["Waldo_fnc_MiniGameChallengeHelp", "MissionScripts\InteractionsMinigames\Core\challengeHelp.sqf"],
    ["Waldo_fnc_MiniGameAccessibility", "MissionScripts\InteractionsMinigames\Core\accessibility.sqf"],
    ["Waldo_fnc_MiniGameApplyAccessibility", "MissionScripts\InteractionsMinigames\Core\applyAccessibility.sqf"],
    ["Waldo_fnc_MiniGameEquipmentProfile", "MissionScripts\InteractionsMinigames\Themes\equipmentProfile.sqf"],
    ["Waldo_fnc_MiniGameEquipmentDifficultyConfig", "MissionScripts\InteractionsMinigames\Themes\equipmentDifficultyConfig.sqf"],
    ["Waldo_fnc_MiniGameEquipmentDecorate", "MissionScripts\InteractionsMinigames\Equipment\equipmentDecorate.sqf"],
    ["Waldo_fnc_MiniGameEquipmentBriefing", "MissionScripts\InteractionsMinigames\Equipment\equipmentBriefing.sqf"],
    ["Waldo_fnc_MiniGameChallengeUI", "MissionScripts\InteractionsMinigames\Core\challengeUi.sqf"],
    ["Waldo_fnc_MiniGameWireCut", "MissionScripts\InteractionsMinigames\Challenges\challengeWireCut.sqf"],
    ["Waldo_fnc_MiniGameMinesweeper", "MissionScripts\InteractionsMinigames\Challenges\challengeMinesweeper.sqf"],
    ["Waldo_fnc_MiniGameKeypad", "MissionScripts\InteractionsMinigames\Challenges\challengeKeypad.sqf"],
    ["Waldo_fnc_MiniGameLockpick", "MissionScripts\InteractionsMinigames\Challenges\challengeLockpick.sqf"],
    ["Waldo_fnc_MiniGameCircuit", "MissionScripts\InteractionsMinigames\Challenges\challengeCircuit.sqf"],
    ["Waldo_fnc_MiniGameRepair", "MissionScripts\InteractionsMinigames\Challenges\challengeRepair.sqf"],
    ["Waldo_fnc_MiniGameRadioTune", "MissionScripts\InteractionsMinigames\Challenges\challengeRadioTune.sqf"],
    ["Waldo_fnc_MiniGamePressure", "MissionScripts\InteractionsMinigames\Challenges\challengePressure.sqf"],
    ["Waldo_fnc_MiniGameSequence", "MissionScripts\InteractionsMinigames\Challenges\challengeSequence.sqf"],
    ["Waldo_fnc_MiniGameCommandInput", "MissionScripts\InteractionsMinigames\Challenges\challengeCommandInput.sqf"],
    ["Waldo_fnc_MiniGameChallenge", "MissionScripts\InteractionsMinigames\Core\miniGameChallenge.sqf"],
    ["Waldo_fnc_MiniGameEquipmentPicker", "MissionScripts\InteractionsMinigames\Integration\equipmentPicker.sqf"],
    ["Waldo_fnc_MiniGameEquipmentGallery", "MissionScripts\InteractionsMinigames\Integration\equipmentGallery.sqf"]
];

{
    _x params ["_name", "_path"];
    missionNamespace setVariable [_name, compile preprocessFileLineNumbers (_root + _path)];
} forEach _functions;

call compile preprocessFileLineNumbers (_root + "init.sqf");
[] execVM (_root + "initPlayerLocal.sqf");
