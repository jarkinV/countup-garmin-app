import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Calendar arithmetic on plain dates, no time of day and no time zones.
// A date is [year, month 1-12, day 1-31]. Everything except today() is pure.
(:glance)
module DateMath {

    const DAY_MILESTONE_STEP = 100;
    const FIRST_YEAR = 1900;

    // Today in the watch's local time zone
    function today() as Array<Number> {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return [info.year, info.month as Number, info.day] as Array<Number>;
    }

    function isLeapYear(year as Number) as Boolean {
        return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    }

    function daysInMonth(year as Number, month as Number) as Number {
        if (month == 2) {
            return isLeapYear(year) ? 29 : 28;
        }
        return (month == 4 || month == 6 || month == 9 || month == 11) ? 30 : 31;
    }

    // Days since 1970-01-01 (Howard Hinnant's days_from_civil). Valid for years >= 0
    function dayNumber(date as Array<Number>) as Number {
        var month = date[1];
        var year = month <= 2 ? date[0] - 1 : date[0];
        var era = year / 400;
        var yearOfEra = year - era * 400;
        var dayOfYear = (153 * (month > 2 ? month - 3 : month + 9) + 2) / 5 + date[2] - 1;
        var dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear;
        return era * 146097 + dayOfEra - 719468;
    }

    // Calendar days from `from` to `to`: 0 on the day itself, +1 at each midnight.
    // A `from` after `to` (watch clock moved back) gives 0
    function daysBetween(from as Array<Number>, to as Array<Number>) as Number {
        var days = dayNumber(to) - dayNumber(from);
        return days > 0 ? days : 0;
    }

    // `date` moved by whole months, day clamped to the target month's length
    function addMonths(date as Array<Number>, months as Number) as Array<Number> {
        var monthIndex = date[0] * 12 + date[1] - 1 + months;
        var year = monthIndex / 12;
        var month = monthIndex % 12 + 1;
        var maxDay = daysInMonth(year, month);
        return [year, month, date[2] < maxDay ? date[2] : maxDay] as Array<Number>;
    }

    // [years, months, days] from `from` to `to`. A month counts once the same day
    // or the last day of a shorter month is reached: 31.01 -> 28.02 = [0, 1, 0].
    // A `from` after `to` gives [0, 0, 0]
    function ymdBetween(from as Array<Number>, to as Array<Number>) as Array<Number> {
        if (dayNumber(to) <= dayNumber(from)) {
            return [0, 0, 0] as Array<Number>;
        }
        var months = (to[0] - from[0]) * 12 + to[1] - from[1];
        var anchor = addMonths(from, months);
        if (dayNumber(anchor) > dayNumber(to)) {
            months -= 1;
            anchor = addMonths(from, months);
        }
        return [months / 12, months % 12, dayNumber(to) - dayNumber(anchor)] as Array<Number>;
    }

    // A picked date made valid: day clamped to the month's length (31 Feb -> 28/29 Feb),
    // then anything after `today` becomes `today`
    function clampDate(date as Array<Number>, today as Array<Number>) as Array<Number> {
        var maxDay = daysInMonth(date[0], date[1]);
        var clamped = [date[0], date[1], date[2] < maxDay ? date[2] : maxDay] as Array<Number>;
        return dayNumber(clamped) > dayNumber(today) ? today : clamped;
    }

    // Every 100 days: 100, 200, ...
    function isDayMilestone(days as Number) as Boolean {
        return days > 0 && days % DAY_MILESTONE_STEP == 0;
    }

    // Whole years with no months or days left, from ymdBetween
    function isAnniversary(ymd as Array<Number>) as Boolean {
        return ymd[0] > 0 && ymd[1] == 0 && ymd[2] == 0;
    }
}
