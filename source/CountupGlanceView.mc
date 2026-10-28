import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Glance row (1 and 2 in PLAN.md): event name small on top, day count below.
// On a milestone day both lines are gold and the name gets " · 1000 days!"
(:glance)
class CountupGlanceView extends WatchUi.GlanceView {

    private const COLOR_GOLD = 0xFFAA00;

    private var _store as EventStore;
    private var _appName as String = "";
    private var _noEvents as String = "";

    function initialize(store as EventStore) {
        GlanceView.initialize();
        _store = store;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _appName = WatchUi.loadResource(Rez.Strings.AppName) as String;
        _noEvents = WatchUi.loadResource(Rez.Strings.NoEvents) as String;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var title = _appName;
        var value = _noEvents;
        var titleColor = Graphics.COLOR_LT_GRAY;
        var valueColor = Graphics.COLOR_WHITE;

        var event = _store.getGlanceEvent();
        if (event != null) {
            var today = DateMath.today();
            var days = DateMath.daysBetween(event.date, today);
            var milestone = Format.milestone(days, DateMath.ymdBetween(event.date, today));
            title = event.name;
            value = Format.dayCount(days);
            if (milestone != null) {
                title += " · " + milestone;
                titleColor = COLOR_GOLD;
                valueColor = COLOR_GOLD;
            }
        }

        var lineHeight = dc.getFontHeight(Graphics.FONT_GLANCE);
        var cy = dc.getHeight() / 2;

        dc.setColor(titleColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, cy - lineHeight / 2, Graphics.FONT_GLANCE, title,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, cy + lineHeight / 2, Graphics.FONT_GLANCE, value,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
