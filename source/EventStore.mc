import Toybox.Application;
import Toybox.Lang;

(:glance)
class CountupEvent {

    var id as Number;
    var name as String;
    var date as Array<Number>;

    function initialize(id as Number, name as String, date as Array<Number>) {
        self.id = id;
        self.name = name;
        self.date = date;
    }
}

// Up to MAX_EVENTS events sorted newest date first, plus which one the glance shows.
// With persist = true it loads from and saves to Application.Storage on every change;
// tests use persist = false and never touch storage.
(:glance)
class EventStore {

    const MAX_EVENTS = 10;
    const MAX_NAME_LENGTH = 20;
    const DEFAULT_NAME_PREFIX = "Event ";

    private const KEY_EVENTS = "events";
    private const KEY_GLANCE_ID = "glanceId";
    private const KEY_NEXT_ID = "nextId";

    private var _persist as Boolean;
    private var _events as Array<CountupEvent> = [] as Array<CountupEvent>;
    private var _glanceId as Number? = null;
    private var _nextId as Number = 1;

    function initialize(persist as Boolean) {
        _persist = persist;
        if (persist) {
            load();
        }
    }

    function size() as Number {
        return _events.size();
    }

    function isFull() as Boolean {
        return _events.size() >= MAX_EVENTS;
    }

    // Event at a position in the sorted list
    function get(index as Number) as CountupEvent {
        return _events[index];
    }

    // Position of the event in the sorted list, -1 if there is none
    function indexOf(id as Number) as Number {
        for (var i = 0; i < _events.size(); i++) {
            if (_events[i].id == id) {
                return i;
            }
        }
        return -1;
    }

    // Adds an event and returns its id, or null when the store is full.
    // An empty name becomes "Event <id>". The first event goes to the glance
    function add(name as String, date as Array<Number>) as Number? {
        if (isFull()) {
            return null;
        }
        var id = _nextId;
        _nextId += 1;
        _events.add(new CountupEvent(id, cleanName(name, id), date));
        if (_glanceId == null) {
            _glanceId = id;
        }
        sort();
        save();
        return id;
    }

    function rename(id as Number, name as String) as Void {
        var index = indexOf(id);
        if (index >= 0) {
            _events[index].name = cleanName(name, id);
            save();
        }
    }

    function setDate(id as Number, date as Array<Number>) as Void {
        var index = indexOf(id);
        if (index >= 0) {
            _events[index].date = date;
            sort();
            save();
        }
    }

    // Removing the glance event moves the glance to the first remaining event
    function remove(id as Number) as Void {
        var index = indexOf(id);
        if (index < 0) {
            return;
        }
        _events.remove(_events[index]);
        if (_glanceId == id) {
            _glanceId = _events.size() > 0 ? _events[0].id : null;
        }
        save();
    }

    function getGlanceId() as Number? {
        return _glanceId;
    }

    function setGlanceId(id as Number) as Void {
        if (indexOf(id) >= 0) {
            _glanceId = id;
            save();
        }
    }

    // The event the glance shows: the chosen one, else the first in the list, else null
    function getGlanceEvent() as CountupEvent? {
        if (_events.size() == 0) {
            return null;
        }
        var index = _glanceId != null ? indexOf(_glanceId) : -1;
        return _events[index >= 0 ? index : 0];
    }

    private function cleanName(name as String, id as Number) as String {
        if (name.length() == 0) {
            return DEFAULT_NAME_PREFIX + id;
        }
        return name.length() > MAX_NAME_LENGTH ? name.substring(0, MAX_NAME_LENGTH) as String : name;
    }

    // Insertion sort: newest date first, same date: added later first. At most 10 items
    private function sort() as Void {
        for (var i = 1; i < _events.size(); i++) {
            var event = _events[i];
            var key = DateMath.dayNumber(event.date);
            var j = i - 1;
            while (j >= 0 && comesBefore(event, key, _events[j])) {
                _events[j + 1] = _events[j];
                j -= 1;
            }
            _events[j + 1] = event;
        }
    }

    private function comesBefore(event as CountupEvent, key as Number, other as CountupEvent) as Boolean {
        var otherKey = DateMath.dayNumber(other.date);
        return key > otherKey || (key == otherKey && event.id > other.id);
    }

    private function load() as Void {
        var stored = Storage.getValue(KEY_EVENTS);
        if (stored instanceof Array) {
            for (var i = 0; i < stored.size(); i++) {
                var item = stored[i] as Dictionary<String, Number or String or Array<Number>>;
                _events.add(new CountupEvent(item["id"] as Number, item["name"] as String,
                    item["date"] as Array<Number>));
            }
        }
        var glanceId = Storage.getValue(KEY_GLANCE_ID);
        _glanceId = glanceId instanceof Number ? glanceId : null;
        var nextId = Storage.getValue(KEY_NEXT_ID);
        _nextId = nextId instanceof Number ? nextId : 1;
        sort();
    }

    private function save() as Void {
        if (!_persist) {
            return;
        }
        var stored = [] as Array<Dictionary<String, Number or String or Array<Number>>>;
        for (var i = 0; i < _events.size(); i++) {
            var event = _events[i];
            stored.add({ "id" => event.id, "name" => event.name, "date" => event.date });
        }
        Storage.setValue(KEY_EVENTS, stored as Storage.ValueType);
        Storage.setValue(KEY_GLANCE_ID, _glanceId);
        Storage.setValue(KEY_NEXT_ID, _nextId);
    }
}
