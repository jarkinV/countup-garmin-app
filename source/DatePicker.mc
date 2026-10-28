import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// One picker column: whole numbers first..last, shown as numbers or as names[value - 1]
class RangeFactory extends WatchUi.PickerFactory {

    private var _first as Number;
    private var _last as Number;
    private var _names as Array<String>?;

    function initialize(first as Number, last as Number, names as Array<String>?) {
        PickerFactory.initialize();
        _first = first;
        _last = last;
        _names = names;
    }

    function getSize() as Number {
        return _last - _first + 1;
    }

    function getValue(item as Number) as Object? {
        return _first + item;
    }

    function getDrawable(item as Number, isSelected as Boolean) as WatchUi.Drawable? {
        var value = _first + item;
        var names = _names;
        return new WatchUi.Text({
            :text => names != null ? names[value - 1] : value.toString(),
            :color => Graphics.COLOR_WHITE,
            :backgroundColor => Graphics.COLOR_BLACK,
            :font => Graphics.FONT_MEDIUM,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
    }
}

// Screen 8: day / month / year columns, years 1900..this year. The watch draws the picker
// on black but the simulator on white, so values are white on their own black box and show
// on both. A day past the month's
// end or a date after today is clamped on accept (DateMath.clampDate)
class DatePicker extends WatchUi.Picker {

    function initialize(initial as Array<Number>) {
        var title = new WatchUi.Text({
            :text => WatchUi.loadResource(Rez.Strings.Date) as String,
            :color => Graphics.COLOR_DK_GRAY,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM
        });
        Picker.initialize({
            :title => title,
            :pattern => [
                new RangeFactory(1, 31, null),
                new RangeFactory(1, 12, Format.MONTHS),
                new RangeFactory(DateMath.FIRST_YEAR, DateMath.today()[0], null)
            ],
            :defaults => [initial[2] - 1, initial[1] - 1, initial[0] - DateMath.FIRST_YEAR]
        });
    }
}

// Hands the clamped [y, m, d] to onDate, which must pop or replace the picker itself.
// Cancel pops the picker and nothing else happens
class DatePickerDelegate extends WatchUi.PickerDelegate {

    private var _onDate as Method(date as Array<Number>) as Void;

    function initialize(onDate as Method(date as Array<Number>) as Void) {
        PickerDelegate.initialize();
        _onDate = onDate;
    }

    function onAccept(values as Array) as Boolean {
        var date = [values[2] as Number, values[1] as Number, values[0] as Number] as Array<Number>;
        _onDate.invoke(DateMath.clampDate(date, DateMath.today()));
        return true;
    }

    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}

// Screen 9: system keyboard. The TextPicker pops itself after enter or cancel
class NameDelegate extends WatchUi.TextPickerDelegate {

    private var _onName as Method(name as String) as Void;

    function initialize(onName as Method(name as String) as Void) {
        TextPickerDelegate.initialize();
        _onName = onName;
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        _onName.invoke(text);
        return true;
    }

    function onCancel() as Boolean {
        return true;
    }
}
