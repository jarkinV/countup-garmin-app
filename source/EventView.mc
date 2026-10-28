import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Event screen (3 and 4 in PLAN.md): one event per page, or the empty state (5)
class EventView extends WatchUi.View {

    const COLOR_GOLD = 0xFFAA00;
    private const DOT_RADIUS = 3;
    private const DOT_SPACING = 11;
    private const DOT_X = 12;
    private const START_MARK_RADIUS = 7;

    private var _store as EventStore;
    private var _index as Number = 0;
    private var _noEvents as String = "";
    private var _pressStart as String = "";
    private var _toAddOne as String = "";

    // Opens on the glance event, the one the user tapped through from
    function initialize(store as EventStore) {
        View.initialize();
        _store = store;
        var glance = store.getGlanceEvent();
        if (glance != null) {
            _index = store.indexOf(glance.id);
        }
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _noEvents = WatchUi.loadResource(Rez.Strings.NoEvents) as String;
        _pressStart = WatchUi.loadResource(Rez.Strings.PressStart) as String;
        _toAddOne = WatchUi.loadResource(Rez.Strings.ToAddOne) as String;
    }

    // Moves by `step` pages, wrapping around the list
    function turnPage(step as Number) as Void {
        var size = _store.size();
        if (size > 1) {
            _index = (_index + step + size) % size;
            WatchUi.requestUpdate();
        }
    }

    // Shows the event with this id, e.g. after adding it; the list may have been resorted
    function showEvent(id as Number) as Void {
        var index = _store.indexOf(id);
        _index = index >= 0 ? index : 0;
        WatchUi.requestUpdate();
    }

    function currentEvent() as CountupEvent? {
        if (_store.size() == 0) {
            return null;
        }
        if (_index >= _store.size()) {
            _index = 0;
        }
        return _store.get(_index);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var event = currentEvent();
        if (event == null) {
            drawEmpty(dc);
        } else {
            drawEvent(dc, event);
            drawPageDots(dc);
        }
    }

    // Name, big day count, unit or milestone label, y/m/d, start date; centered as a block
    private function drawEvent(dc as Graphics.Dc, event as CountupEvent) as Void {
        var today = DateMath.today();
        var days = DateMath.daysBetween(event.date, today);
        var ymd = DateMath.ymdBetween(event.date, today);
        var milestone = Format.milestone(days, ymd);
        var accent = milestone != null ? COLOR_GOLD : Graphics.COLOR_WHITE;

        var numberFont = Graphics.FONT_NUMBER_THAI_HOT;
        var smallHeight = dc.getFontHeight(Graphics.FONT_SMALL);
        var tinyHeight = dc.getFontHeight(Graphics.FONT_XTINY);
        var restHeight = smallHeight * 3 + tinyHeight;
        if (dc.getFontHeight(numberFont) + restHeight > dc.getHeight() * 4 / 5) {
            numberFont = Graphics.FONT_NUMBER_HOT;
        }
        var numberHeight = dc.getFontHeight(numberFont);

        var cx = dc.getWidth() / 2;
        var y = (dc.getHeight() - numberHeight - restHeight) / 2;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL, event.name, Graphics.TEXT_JUSTIFY_CENTER);
        y += smallHeight;

        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, numberFont, days.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        y += numberHeight;
        dc.drawText(cx, y, Graphics.FONT_SMALL, milestone != null ? milestone : Format.dayUnit(days),
            Graphics.TEXT_JUSTIFY_CENTER);
        y += smallHeight;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL, Format.ymd(ymd), Graphics.TEXT_JUSTIFY_CENTER);
        y += smallHeight;

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, "since " + Format.date(event.date), Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Vertical dots on the left edge: position in the list. Hidden for a single event
    private function drawPageDots(dc as Graphics.Dc) as Void {
        var size = _store.size();
        if (size < 2) {
            return;
        }
        var top = dc.getHeight() / 2 - (size - 1) * DOT_SPACING / 2;
        for (var i = 0; i < size; i++) {
            dc.setColor(i == _index ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(DOT_X, top + i * DOT_SPACING, DOT_RADIUS);
        }
    }

    // "No events / Press START / to add one" and a gold ring by the START button (upper right, 30°)
    private function drawEmpty(dc as Graphics.Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var lineHeight = dc.getFontHeight(Graphics.FONT_SMALL);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - lineHeight, Graphics.FONT_MEDIUM, _noEvents,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + lineHeight / 2, Graphics.FONT_SMALL, _pressStart,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy + lineHeight * 3 / 2, Graphics.FONT_SMALL, _toAddOne,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // cos 30° = 0.866, sin 30° = 0.5; inset so the whole ring stays on screen
        var r = cx - START_MARK_RADIUS - 6;
        dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx + (r * 0.866).toNumber(), cy - r / 2, START_MARK_RADIUS);
        dc.setPenWidth(1);
    }
}
