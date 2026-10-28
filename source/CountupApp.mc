import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class CountupApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var store = new EventStore(true);
        var view = new EventView(store);
        return [view, new EventDelegate(view, new EventFlows(store, view))];
    }

    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new CountupGlanceView(new EventStore(true))];
    }
}
