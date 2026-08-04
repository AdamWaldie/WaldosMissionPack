/*
 * Author: WaldoTheWarfighter
 * Adds landing-zone sizing, formation and map-marking guidance to the player's map diary.
 * This client-only function is called by Waldo_fnc_AddDocs during player setup.
 *
 * Arguments: None
 * Return Value: Nothing
 *
 * Example:
 * call Waldo_fnc_LZSPECS;
 */

player createDiaryRecord ["Checklists", ["Landing Zone Specifications", "
<font color='#addde6' size='20'>LANDING ZONE SPECIFICATIONS</font><br/><br/>
<font color='#addde6' size='16'>MINIMUM CLEAR DIAMETER</font><br/>
<font color='#d8f2f7'>25 m</font> — OH-58, MH-6<br/>
<font color='#d8f2f7'>35 m</font> — UH-1, AH-1<br/>
<font color='#d8f2f7'>50 m</font> — UH-60, AH-64<br/>
<font color='#d8f2f7'>80 m</font> — CH-47<br/>
<font color='#d8f2f7'>100 m</font> — all sling loads<br/><br/>
<font color='#addde6' size='16'>MULTI-AIRCRAFT FORMATIONS</font><br/>
Add 100 m to approach and 100 m to departure where terrain allows.<br/>
• <font color='#d8f2f7'>Single:</font> 50 × 50 m.<br/>
• <font color='#d8f2f7'>Echelon right:</font> approximately 100 × 100 m.<br/>
• <font color='#d8f2f7'>Trail:</font> approximately 50 × 150 m.<br/>
• <font color='#d8f2f7'>Vee:</font> approximately 150 × 100 m.<br/>
• <font color='#d8f2f7'>Diamond:</font> approximately 150 × 150 m.<br/>
• <font color='#d8f2f7'>Wedge, heavy left:</font> approximately 200 × 150 m.<br/><br/>
<font color='#addde6' size='16'>MAP MARKING</font><br/>
Mark the LZ name, intended formation and approach heading. Mark the rally point, wind direction, tall trees, telephone poles, power lines and other hazards. Keep the diagram readable and make hazards obvious to aircrew.<br/><br/>
<font color='#f0c674'>These are planning guides. Increase clearance for weather, terrain, pilot visibility, aircraft type and mission load.</font>
"]];
