/*
 * Author: Waldo
 * Adds the Call For Fire (CFF) procedure reference to the player's map diary.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call Waldo_fnc_CALLFORFIRE;
 */

player createDiaryRecord["Support Calls",
    ["CALL FOR FIRE",
        "
<img image='MissionScripts\MissionInit\BriefingDocuments\BriefImages\CFF.jpg' width='367' height='587'/>
        "
    ]
];