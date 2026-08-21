/*
 * Author: WaldoTheWarfighter
 * Supplies the opt-in medieval Dornow dialogue example derived from val_dialogue.sqf.
 * Locality/authority: pure server-loaded data. Repeat/JIP behaviour: no side effects.
 * Arguments: None. Return Value: HASHMAP of archetype ID to ARRAY<STRING>.
 * Current caller: Waldo_fnc_DialogueLoadPresetPack. Example: ["MEDIEVAL_DORNOW"] call Waldo_fnc_DialogueLoadPresetPack;
 */
createHashMapFromArray [
    ["DORNOW_CIVILIAN", ["You're with Dornow?", "White and blue, thank Christ!", "Hello?", "Jesus Christ be praised!", "...as we forgive those who trespass against us...", "Give those Cumans hell, eh?", "What a miserable bloody day.", "Praise be!", "Morning, Guardsman.", "Thought I saw something in the trees...", "Winds howling..."]],
    ["DORNOW_GUARD", ["Praise be!", "Need somethin'?", "Yeah?", "Morning, brother.", "Dornow watches.", "Gods, my feet ache.", "Nice day, ya think?", "Captain's got a plan, surely.", "Swear I saw that bastard get back up..."]],
    ["DORNOW_SHOPKEEPER", ["Need somethin'?", "Can I help you?", "Nice day, isn't it?", "What can I get ya?", "No touchin' unless you're buyin'!", "Try and nick somethin' and I'll have yer hands!", "Finest wares this side of the Avery Sea!", "I've got wares if you've got coin.", "Fancy a bargain?"]],
    ["DORNOW_FARMER", ["Can I help ya?", "Nice day, isn't it?", "What do you want?", "Do I know you?", "Bugger off.", "Quit standin' on me crops!", "It ain't much, but it's honest work.", "Get off me land before I set me dog on ye!"]]
]
