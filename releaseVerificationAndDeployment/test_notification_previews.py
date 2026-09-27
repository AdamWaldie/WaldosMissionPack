"""Static contracts for shared rendering and isolation of pending UI preferences."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
FLOW = ROOT / "MissionScripts" / "MissionFlowAndUi"

def source(name):
    return (FLOW / name).read_text(encoding="utf-8")

class NotificationPreviewTests(unittest.TestCase):
    def test_preview_and_live_cards_share_registered_renderers(self):
        settings = source("Accessibility/uiNotificationSettingsOpenLocal.sqf")
        functions = (ROOT / "MissionScripts/WaldosFunctions.sqf").read_text(encoding="utf-8")
        for name, caller in (("CreateUiNotificationCardLocal", "showUiNotification.sqf"),
                             ("LayoutUiNotificationCardLocal", "reflowUiPanels.sqf")):
            self.assertIn(f"Waldo_fnc_{name}", settings)
            self.assertIn(f"Waldo_fnc_{name}", source(caller))
            self.assertIn(f"class {name}", functions)
        self.assertIn('forEach [_themeCombo, _sizeCombo, _motionCombo]', settings)

    def test_pending_preview_is_isolated_and_replaces_its_controls(self):
        settings = source("Accessibility/uiNotificationSettingsOpenLocal.sqf")
        refresh = settings.split('private _refresh = {', 1)[1].split('private _buttonY', 1)[0]
        self.assertIn('ctrlDelete _x', refresh)
        self.assertIn('Waldo_UI_OwnStyle', refresh)
        for text in (refresh, source('createUiNotificationCardLocal.sqf'), source('layoutUiNotificationCardLocal.sqf')):
            for forbidden in ('profileNamespace setVariable', 'missionNamespace setVariable',
                              'Waldo_UiPanelRegistry', 'Waldo_UiPanelQueue', 'remoteExec'):
                self.assertNotIn(forbidden, text)
        layout = source('layoutUiNotificationCardLocal.sqf')
        self.assertIn('_entry params ["_channel", "_controls", "_token", "_slot", "_panelW", "_panelH"', layout)
        self.assertNotIn('_reservations', layout)
        self.assertNotIn('_cursor', layout)

    def test_curator_preview_override_survives_queue_and_restyle(self):
        show = source('showUiNotification.sqf')
        self.assertIn('diag_tickTime + _ttl, _previewThemeId]', show)
        self.assertIn('_entry set [17, _previewThemeId]', show)
        self.assertIn('_entry param [17, ""]', source('restyleUiNotificationsLocal.sqf'))
        self.assertEqual(source('uiThemeApplyLocal.sqf').count('false, false, 0, 0, _themeId]'), 3)

    def test_hud_pending_preferences_do_not_overwrite_saved_cache(self):
        prefs = source('WmpHud/wmpHudPreferences.sqf')
        self.assertIn('if (_pending isEqualTo []) then {missionNamespace setVariable', prefs)
        settings = source('WmpHud/wmpHudSettingsOpenLocal.sqf')
        self.assertIn('call Waldo_fnc_WmpHudPreferences', settings)
        self.assertIn('(_preferences get "scale")', settings)
        self.assertIn('(_preferences get "opacity")', settings)
        self.assertIn('Waldo_WmpHud_Icon', settings)
        self.assertIn('Waldo_WmpHud_Colour', settings)

if __name__ == '__main__':
    unittest.main()
