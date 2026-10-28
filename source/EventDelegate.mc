import Toybox.Lang;
import Toybox.WatchUi;

// UP/DOWN and swipes turn pages. START (onKey KEY_ENTER, not onSelect, so screen
// taps do nothing) and MENU (long UP) open the menu, or Add when there are no events.
// BACK exits by default
class EventDelegate extends WatchUi.BehaviorDelegate {

    private var _view as EventView;
    private var _flows as EventFlows;

    function initialize(view as EventView, flows as EventFlows) {
        BehaviorDelegate.initialize();
        _view = view;
        _flows = flows;
    }

    function onNextPage() as Boolean {
        _view.turnPage(1);
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.turnPage(-1);
        return true;
    }

    function onMenu() as Boolean {
        _flows.openMenu();
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        if (keyEvent.getKey() == WatchUi.KEY_ENTER) {
            _flows.openMenu();
            return true;
        }
        return false;
    }
}
