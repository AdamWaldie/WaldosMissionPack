/*
 * Author: WaldoTheWarfighter
 * Adds the nine-line close air support brief to the player's map diary.
 * This client-only function is called by Waldo_fnc_AddDocs during player setup.
 *
 * Arguments: None
 * Return Value: Nothing
 *
 * Example:
 * call Waldo_fnc_NINELINE;
 */

player createDiaryRecord ["Support Calls", ["9-Line CAS Brief", "
<font color='#addde6' size='20'>9-LINE CLOSE AIR SUPPORT BRIEF</font><br/><br/>
<font color='#d8f2f7'>1. IP / BP</font> — initial point for fixed wing, or battle position for rotary wing.<br/>
<font color='#d8f2f7'>2. Heading</font> — magnetic heading from IP/BP to target; state left or right offset.<br/>
<font color='#d8f2f7'>3. Distance</font> — kilometres for fixed wing; metres from BP centre for rotary wing.<br/>
<font color='#d8f2f7'>4. Target elevation</font> — feet above mean sea level.<br/>
<font color='#d8f2f7'>5. Target description</font> — number, type, activity and protection.<br/>
<font color='#d8f2f7'>6. Target location</font> — include a ten-figure grid where possible.<br/>
<font color='#d8f2f7'>7. Mark</font> — WP, illumination, laser or IR pointer; include laser code.<br/>
<font color='#d8f2f7'>8. Friendlies</font> — direction and distance in metres from the target.<br/>
<font color='#d8f2f7'>9. Egress</font> — say 'EGRESS', then give direction and location as required.<br/><br/>
<font color='#f0c674'>Await read-back.</font> Confirm: 'Read-back correct. Say when ready to copy remarks.'<br/><br/>
<font color='#addde6'>REMARKS</font><br/>
• Altitude restrictions and no-fly areas.<br/>
• Final attack heading in degrees magnetic.<br/>
• Threat type, direction and distance; include suppression details.<br/>
• Time on target, time to target, or 'Push ASAP.'<br/><br/>
Ask for readiness, then provide a big-to-small talk-on to the target.
"]];
