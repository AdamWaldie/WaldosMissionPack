/*
 * Author: WaldoTheWarfighter
 * Adds jumpmaster administration, drop sequence and stick-brief guidance to the player's map diary.
 * This client-only function is called by Waldo_fnc_AddDocs during player setup.
 *
 * Arguments: None
 * Return Value: Nothing
 *
 * Example:
 * call Waldo_fnc_JUMPMASTER;
 */

player createDiaryRecord ["Checklists", ["Jumpmaster Checklists", "
<font color='#addde6' size='20'>JUMPMASTER CHECKLISTS</font><br/><br/>
<font color='#addde6' size='16'>ADMINISTRATION</font><br/>
<font color='#d8f2f7'>1. Meet OIC</font> — confirm the marked drop zone, loading assembly point and number of sticks.<br/>
<font color='#d8f2f7'>2. Coordinate</font> — confirm jump order, aircraft and stick loading.<br/>
<font color='#d8f2f7'>3. Brief pilots</font> — route, ingress, egress, 300 m altitude and 240 km/h airspeed; jump frequency for the aircraft.<br/>
<font color='#d8f2f7'>4. Move</font> — assemble and await troopers.<br/>
<font color='#d8f2f7'>5. Organise and brief stick</font> — use the guidance below.<br/>
<font color='#d8f2f7'>6. Load</font> — load by stick order, teleport or boarding doors. Jumpmaster boards last.<br/><br/>
<font color='#addde6' size='16'>DROP SEQUENCE</font><br/>
<font color='#d8f2f7'>Monitor</font> — track transit to the drop zone.<br/>
<font color='#d8f2f7'>Get ready</font> — issue at approximately 30 seconds; troopers prepare to jump.<br/>
<font color='#d8f2f7'>Stand by</font> — issue at 10–15 seconds; troopers prepare the jump action.<br/>
<font color='#d8f2f7'>Go, go, go</font> — call numbers from one at approximately one trooper every two seconds.<br/>
<font color='#d8f2f7'>Red light</font> — stop jumping at the end of the zone. Tell aircrew whether the aircraft is empty or another pass is required; jumpmaster exits last where possible.<br/><br/>
<font color='#addde6' size='16'>ORGANISE THE STICK</font><br/>
Normally two squads plus staff, up to 24 troopers excluding jumpmaster. Keep buddy teams together; place command elements centrally with a jump buddy. Number every trooper from one and make each remember their place.<br/><br/>
<font color='#addde6' size='16'>BRIEF THE STICK</font><br/>
• Jump frequency; increment for later sticks when required.<br/>
• Drop zone, route and rally-point grid.<br/>
• Timings, sequence and jump commands.<br/>
• Aircraft or pass order.<br/>
• Procedure for medical support on the drop zone.<br/>
• Questions.
"]];
