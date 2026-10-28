import Toybox.Lang;
import Toybox.WatchUi;

// Menu (6), Edit (7), pickers (8, 9) and Delete confirmation (10) from PLAN.md.
// View stack rules: Add and Delete pop the menu first, so they always end on the
// event screen; Edit stays in its submenu and refreshes the sublabels after each change
class EventFlows {

    private var _store as EventStore;
    private var _view as EventView;
    private var _pendingDate as Array<Number>? = null;
    private var _editId as Number = 0;
    private var _menu as Menu2? = null;
    private var _editMenu as Menu2? = null;

    function initialize(store as EventStore, view as EventView) {
        _store = store;
        _view = view;
    }

    // START / MENU on the event screen; with no events goes straight to Add
    function openMenu() as Void {
        var event = _view.currentEvent();
        if (event == null) {
            startAdd();
            return;
        }
        var menu = new WatchUi.Menu2({ :title => event.name });
        if (!_store.isFull()) {
            menu.addItem(new WatchUi.MenuItem(Rez.Strings.AddEvent, null, :add, null));
        }
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.Edit, null, :edit, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.Delete, null, :delete, null));
        var inGlance = _store.getGlanceId() == event.id;
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.ShowInGlance,
            inGlance ? WatchUi.loadResource(Rez.Strings.InGlanceNow) as String : null, :glance, null));
        _menu = menu;
        WatchUi.pushView(menu, new MenuDelegate(method(:onMenuSelect)), WatchUi.SLIDE_UP);
    }

    function onMenuSelect(id as Object?) as Void {
        var event = _view.currentEvent();
        if (event == null) {
            return;
        }
        if (id == :add) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            startAdd();
        } else if (id == :edit) {
            openEdit(event);
        } else if (id == :delete) {
            _editId = event.id;
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            var prompt = WatchUi.loadResource(Rez.Strings.DeletePrompt) as String;
            WatchUi.pushView(new WatchUi.Confirmation(prompt + " \"" + event.name + "\"?"),
                new DeleteDelegate(method(:onDeleteConfirmed)), WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :glance) {
            _store.setGlanceId(event.id);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    // Add: date picker, then name. Cancelling either step saves nothing
    function startAdd() as Void {
        WatchUi.pushView(new DatePicker(DateMath.today()), new DatePickerDelegate(method(:onAddDate)),
            WatchUi.SLIDE_LEFT);
    }

    function onAddDate(date as Array<Number>) as Void {
        if (WatchUi has :TextPicker) {
            _pendingDate = date;
            WatchUi.switchToView(new WatchUi.TextPicker(""), new NameDelegate(method(:onAddName)),
                WatchUi.SLIDE_LEFT);
        } else {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            finishAdd(date, "");
        }
    }

    function onAddName(name as String) as Void {
        var date = _pendingDate;
        _pendingDate = null;
        if (date != null) {
            finishAdd(date, name);
        }
    }

    private function finishAdd(date as Array<Number>, name as String) as Void {
        var id = _store.add(name, date);
        if (id != null) {
            _view.showEvent(id);
        }
    }

    // Edit: submenu with Name and Date, current values as sublabels
    private function openEdit(event as CountupEvent) as Void {
        _editId = event.id;
        var menu = new WatchUi.Menu2({ :title => Rez.Strings.Edit });
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.Name, event.name, :name, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.Date, Format.date(event.date), :date, null));
        _editMenu = menu;
        WatchUi.pushView(menu, new MenuDelegate(method(:onEditSelect)), WatchUi.SLIDE_LEFT);
    }

    function onEditSelect(id as Object?) as Void {
        var event = editedEvent();
        if (event == null) {
            return;
        }
        if (id == :name && WatchUi has :TextPicker) {
            WatchUi.pushView(new WatchUi.TextPicker(event.name), new NameDelegate(method(:onEditName)),
                WatchUi.SLIDE_LEFT);
        } else if (id == :date) {
            WatchUi.pushView(new DatePicker(event.date), new DatePickerDelegate(method(:onEditDate)),
                WatchUi.SLIDE_LEFT);
        }
    }

    function onEditName(name as String) as Void {
        _store.rename(_editId, name);
        refreshMenus();
    }

    function onEditDate(date as Array<Number>) as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        _store.setDate(_editId, date);
        _view.showEvent(_editId);
        refreshMenus();
    }

    // New name and date in the Edit sublabels and the main menu title
    private function refreshMenus() as Void {
        var event = editedEvent();
        var editMenu = _editMenu;
        if (event == null || editMenu == null) {
            return;
        }
        (editMenu.getItem(0) as MenuItem).setSubLabel(event.name);
        (editMenu.getItem(1) as MenuItem).setSubLabel(Format.date(event.date));
        var menu = _menu;
        if (menu != null) {
            menu.setTitle(event.name);
        }
        WatchUi.requestUpdate();
    }

    private function editedEvent() as CountupEvent? {
        var index = _store.indexOf(_editId);
        return index >= 0 ? _store.get(index) : null;
    }

    // Delete: the event screen then shows the next event, or the empty state
    function onDeleteConfirmed() as Void {
        _store.remove(_editId);
        WatchUi.requestUpdate();
    }
}

class MenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _onSelect as Method(id as Object?) as Void;

    function initialize(onSelect as Method(id as Object?) as Void) {
        Menu2InputDelegate.initialize();
        _onSelect = onSelect;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        _onSelect.invoke(item.getId());
    }
}

// Confirmation pops itself; only Yes calls onYes
class DeleteDelegate extends WatchUi.ConfirmationDelegate {

    private var _onYes as Method() as Void;

    function initialize(onYes as Method() as Void) {
        ConfirmationDelegate.initialize();
        _onYes = onYes;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _onYes.invoke();
        }
        return true;
    }
}
