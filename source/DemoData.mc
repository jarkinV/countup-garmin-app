import Toybox.Application;
import Toybox.Lang;

// Fixed sample events for README screenshots. Only the screenshot build
// (screenshots.jungle, which excludes `nodemo` instead of `demo`) has the real reset;
// normal debug and release builds get the empty one.
(:glance)
module DemoData {

    // Replaces all stored events on every start, so each capture looks the same
    (:demo)
    function reset() as Void {
        Storage.clearValues();
        var store = new EventStore(true);
        var today = DateMath.today();
        store.add("Moved", [2019, 3, 1] as Array<Number>);
        var sober = store.add("Sober", [2023, 6, 12] as Array<Number>) as Number;
        store.add("Married", DateMath.addMonths(today, -36));
        store.add("Running", daysBefore(today, 1000));
        store.setGlanceId(sober);
    }

    (:nodemo)
    function reset() as Void {
    }

    // The date `days` before `date` (Howard Hinnant's civil_from_days on DateMath.dayNumber)
    (:demo)
    function daysBefore(date as Array<Number>, days as Number) as Array<Number> {
        var z = DateMath.dayNumber(date) - days + 719468;
        var era = z / 146097;
        var dayOfEra = z - era * 146097;
        var yearOfEra = (dayOfEra - dayOfEra / 1460 + dayOfEra / 36524 - dayOfEra / 146096) / 365;
        var dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100);
        var mp = (5 * dayOfYear + 2) / 153;
        var day = dayOfYear - (153 * mp + 2) / 5 + 1;
        var month = mp < 10 ? mp + 3 : mp - 9;
        var year = yearOfEra + era * 400 + (month <= 2 ? 1 : 0);
        return [year, month, day] as Array<Number>;
    }
}
