import Toybox.Lang;
import Toybox.Test;

(:test)
module EventStoreTest {

    function date(year as Number, month as Number, day as Number) as Array<Number> {
        return [year, month, day] as Array<Number>;
    }

    // Names in list order, joined with commas
    function order(store as EventStore) as String {
        var names = "";
        for (var i = 0; i < store.size(); i++) {
            names += (i > 0 ? "," : "") + store.get(i).name;
        }
        return names;
    }

    (:test)
    function emptyStore(logger as Logger) as Boolean {
        var store = new EventStore(false);
        return store.size() == 0 && store.getGlanceEvent() == null && store.getGlanceId() == null;
    }

    (:test)
    function sortedNewestFirst(logger as Logger) as Boolean {
        var store = new EventStore(false);
        store.add("B", date(2020, 5, 1));
        store.add("A", date(2024, 1, 1));
        store.add("C", date(2010, 12, 31));
        logger.debug("order = " + order(store));
        return order(store).equals("A,B,C");
    }

    (:test)
    function sameDateLaterAddedFirst(logger as Logger) as Boolean {
        var store = new EventStore(false);
        store.add("Old", date(2020, 5, 1));
        store.add("New", date(2020, 5, 1));
        return order(store).equals("New,Old");
    }

    (:test)
    function setDateResorts(logger as Logger) as Boolean {
        var store = new EventStore(false);
        var a = store.add("A", date(2024, 1, 1)) as Number;
        store.add("B", date(2020, 1, 1));
        store.setDate(a, date(2000, 1, 1));
        logger.debug("order = " + order(store));
        return order(store).equals("B,A") && store.get(1).date[0] == 2000;
    }

    (:test)
    function limitIsTen(logger as Logger) as Boolean {
        var store = new EventStore(false);
        for (var i = 0; i < 10; i++) {
            store.add("E", date(2020, 1, i + 1));
        }
        return store.isFull() && store.add("Extra", date(2021, 1, 1)) == null && store.size() == 10;
    }

    (:test)
    function emptyNameGetsDefault(logger as Logger) as Boolean {
        var store = new EventStore(false);
        store.add("First", date(2020, 1, 1));
        var id = store.add("", date(2021, 1, 1)) as Number;
        var name = store.get(store.indexOf(id)).name;
        logger.debug("name = " + name);
        return name.equals("Event 2");
    }

    (:test)
    function longNameTruncated(logger as Logger) as Boolean {
        var store = new EventStore(false);
        var id = store.add("ABCDEFGHIJKLMNOPQRSTUVWXYZ", date(2020, 1, 1)) as Number;
        store.rename(id, "abcdefghijklmnopqrstuvwxyz");
        return store.get(0).name.equals("abcdefghijklmnopqrst");
    }

    (:test)
    function renameEmptyGetsDefault(logger as Logger) as Boolean {
        var store = new EventStore(false);
        var id = store.add("Named", date(2020, 1, 1)) as Number;
        store.rename(id, "");
        return store.get(0).name.equals("Event " + id);
    }

    (:test)
    function firstAddedGoesToGlance(logger as Logger) as Boolean {
        var store = new EventStore(false);
        var first = store.add("First", date(2020, 1, 1)) as Number;
        store.add("Newer", date(2024, 1, 1));
        var glance = store.getGlanceEvent() as CountupEvent;
        return store.getGlanceId() == first && glance.id == first;
    }

    (:test)
    function setGlanceIdChangesGlance(logger as Logger) as Boolean {
        var store = new EventStore(false);
        store.add("First", date(2020, 1, 1));
        var second = store.add("Second", date(2024, 1, 1)) as Number;
        store.setGlanceId(second);
        store.setGlanceId(999);
        return (store.getGlanceEvent() as CountupEvent).id == second;
    }

    (:test)
    function removingGlanceEventFallsBackToFirst(logger as Logger) as Boolean {
        var store = new EventStore(false);
        var old = store.add("Old", date(2010, 1, 1)) as Number;
        store.add("Middle", date(2015, 1, 1));
        var newest = store.add("Newest", date(2024, 1, 1)) as Number;
        store.remove(old);
        return store.size() == 2 && store.getGlanceId() == newest
            && (store.getGlanceEvent() as CountupEvent).id == newest;
    }

    (:test)
    function removingOtherEventKeepsGlance(logger as Logger) as Boolean {
        var store = new EventStore(false);
        var first = store.add("First", date(2010, 1, 1)) as Number;
        var other = store.add("Other", date(2024, 1, 1)) as Number;
        store.remove(other);
        return store.getGlanceId() == first && order(store).equals("First");
    }

    (:test)
    function removingLastEventEmptiesGlance(logger as Logger) as Boolean {
        var store = new EventStore(false);
        var only = store.add("Only", date(2010, 1, 1)) as Number;
        store.remove(only);
        var again = store.add("Again", date(2011, 1, 1)) as Number;
        return store.size() == 1 && store.getGlanceId() == again && again != only;
    }

    (:test)
    function unknownIdsIgnored(logger as Logger) as Boolean {
        var store = new EventStore(false);
        store.add("A", date(2020, 1, 1));
        store.rename(999, "X");
        store.setDate(999, date(2000, 1, 1));
        store.remove(999);
        return store.indexOf(999) == -1 && order(store).equals("A");
    }
}
