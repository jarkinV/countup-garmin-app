import Toybox.Lang;
import Toybox.Test;

(:test)
module FormatTest {

    function ymd(years as Number, months as Number, days as Number) as Array<Number> {
        return [years, months, days] as Array<Number>;
    }

    (:test)
    function dayCountSingular(logger as Logger) as Boolean {
        return Format.dayCount(0).equals("0 days")
            && Format.dayCount(1).equals("1 day")
            && Format.dayCount(1234).equals("1234 days");
    }

    (:test)
    function ymdText(logger as Logger) as Boolean {
        return Format.ymd(ymd(3, 4, 17)).equals("3y 4m 17d") && Format.ymd(ymd(0, 0, 0)).equals("0y 0m 0d");
    }

    (:test)
    function dateText(logger as Logger) as Boolean {
        return Format.date([2023, 6, 12] as Array<Number>).equals("12 Jun 2023")
            && Format.date([1900, 1, 1] as Array<Number>).equals("1 Jan 1900")
            && Format.date([2025, 12, 31] as Array<Number>).equals("31 Dec 2025");
    }

    (:test)
    function noMilestone(logger as Logger) as Boolean {
        return Format.milestone(1234, ymd(3, 4, 17)) == null && Format.milestone(0, ymd(0, 0, 0)) == null;
    }

    (:test)
    function dayMilestoneText(logger as Logger) as Boolean {
        return (Format.milestone(1000, ymd(2, 8, 26)) as String).equals("1000 days!");
    }

    (:test)
    function anniversaryText(logger as Logger) as Boolean {
        return (Format.milestone(365, ymd(1, 0, 0)) as String).equals("1 year!")
            && (Format.milestone(1095, ymd(3, 0, 0)) as String).equals("3 years!");
    }

    (:test)
    function anniversaryWinsOverDays(logger as Logger) as Boolean {
        // Both rules match: the anniversary label is shown
        return (Format.milestone(36500, ymd(100, 0, 0)) as String).equals("100 years!");
    }
}
