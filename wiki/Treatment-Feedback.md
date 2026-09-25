# Treatment Feedback

> **Use this page when:** patients should see clear start, completion and interruption feedback for ACE medical treatment.

Treatment Feedback shows a WMP card to the patient during ACE Medical actions. The medic can receive a separate card if the mission maker enables that choice. The card reports the real ACE treatment result. It does not run on an unrelated timer.

## Enable it

ACE Medical is required. Open `MissionConfig/interfaceConfig.sqf` and change the existing `Waldo_TreatmentFeedback_Enable` row from `false` to `true`. Start the mission and treat a wounded player. The patient should see the start card, followed by a completion or failure card. No object placement or ZEN module is needed.

## Choose the cards

The existing `Waldo_TreatmentFeedback_ShowStart`, `ShowSuccess` and `ShowFailure` rows all start `true`. `NotifyPatient` starts `true`. `NotifyMedic` starts `false`. `ShowMedicName` and `ShowBodyPart` start `true`. `Duration = 3` seconds is how long a resulting card remains after the ACE event, not the treatment duration. The title rows contain the visible card headings. Optional treatment-name and body-part maps let a mission use its own readable labels.

The notification uses a padded bottom-centre specialist area and follows the shared visual theme. It replaces an earlier treatment card instead of stacking every rapid event across the screen.

## If feedback is missing

Check that ACE Medical is loaded, the enable row is `true`, and the intended recipient option is on. A treatment that never finishes does not produce a success card. `Waldo_fnc_TreatmentFeedbackInit` and `Waldo_fnc_TreatmentFeedbackStop` reinstall or remove the client-side listeners if your mission changes the setting during play. WMP installs them for joining players when enabled.

## See also

- [Custom UI Notifications](Custom-UI-Notifications)
- [UI Visual Themes](UI-Visual-Themes)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
