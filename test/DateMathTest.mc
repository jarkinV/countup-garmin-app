import Toybox.Lang;
import Toybox.Test;

(:test)
module DateMathTest {

    function date(year as Number, month as Number, day as Number) as Array<Number> {
        return [year, month, day] as Array<Number>;
    }

    function ymdIs(logger as Logger, from as Array<Number>, to as Array<Number>,
            years as Number, months as Number, days as Number) as Boolean {
        var ymd = DateMath.ymdBetween(from, to);
        logger.debug("ymd = " + ymd);
        return ymd[0] == years && ymd[1] == months && ymd[2] == days;
    }

    // daysBetween

    (:test)
    function sameDayIsZero(logger as Logger) as Boolean {
        return DateMath.daysBetween(date(2026, 10, 1), date(2026, 10, 1)) == 0;
    }

    (:test)
    function plainDifference(logger as Logger) as Boolean {
        return DateMath.daysBetween(date(2026, 10, 1), date(2026, 10, 3)) == 2;
    }

    (:test)
    function acrossLeapDay(logger as Logger) as Boolean {
        return DateMath.daysBetween(date(2024, 2, 28), date(2024, 3, 1)) == 2
            && DateMath.daysBetween(date(2023, 2, 28), date(2023, 3, 1)) == 1;
    }

    (:test)
    function acrossYearEnd(logger as Logger) as Boolean {
        return DateMath.daysBetween(date(2025, 12, 31), date(2026, 1, 1)) == 1;
    }

    (:test)
    function longSpan(logger as Logger) as Boolean {
        // Reference values from Python's datetime.date subtraction
        var days = DateMath.daysBetween(date(2000, 1, 1), date(2026, 10, 28));
        logger.debug("days = " + days);
        return days == 9797 && DateMath.daysBetween(date(2023, 6, 12), date(2026, 10, 29)) == 1235;
    }

    (:test)
    function oldestAllowedDate(logger as Logger) as Boolean {
        return DateMath.daysBetween(date(1900, 1, 1), date(1900, 3, 1)) == 59;
    }

    (:test)
    function futureIsZero(logger as Logger) as Boolean {
        return DateMath.daysBetween(date(2026, 10, 29), date(2026, 10, 28)) == 0;
    }

    // ymdBetween

    (:test)
    function ymdSameDay(logger as Logger) as Boolean {
        return ymdIs(logger, date(2026, 10, 1), date(2026, 10, 1), 0, 0, 0);
    }

    (:test)
    function ymdTypical(logger as Logger) as Boolean {
        return ymdIs(logger, date(2023, 6, 12), date(2026, 10, 29), 3, 4, 17);
    }

    (:test)
    function ymdDayNotReachedYet(logger as Logger) as Boolean {
        return ymdIs(logger, date(2026, 3, 15), date(2026, 4, 14), 0, 0, 30);
    }

    (:test)
    function ymdMonthEndClampsToShorterMonth(logger as Logger) as Boolean {
        return ymdIs(logger, date(2025, 1, 31), date(2025, 2, 28), 0, 1, 0)
            && ymdIs(logger, date(2024, 1, 31), date(2024, 2, 29), 0, 1, 0)
            && ymdIs(logger, date(2025, 1, 31), date(2025, 2, 27), 0, 0, 27)
            && ymdIs(logger, date(2025, 1, 31), date(2025, 3, 1), 0, 1, 1);
    }

    (:test)
    function ymdLeapDayAnniversary(logger as Logger) as Boolean {
        return ymdIs(logger, date(2024, 2, 29), date(2025, 2, 28), 1, 0, 0)
            && ymdIs(logger, date(2024, 2, 29), date(2025, 3, 1), 1, 0, 1)
            && ymdIs(logger, date(2024, 2, 29), date(2028, 2, 29), 4, 0, 0);
    }

    (:test)
    function ymdAcrossYearEnd(logger as Logger) as Boolean {
        return ymdIs(logger, date(2025, 11, 20), date(2026, 1, 5), 0, 1, 16);
    }

    (:test)
    function ymdFutureIsZero(logger as Logger) as Boolean {
        return ymdIs(logger, date(2026, 10, 29), date(2026, 10, 28), 0, 0, 0);
    }

    // clampDate

    function sameDate(a as Array<Number>, b as Array<Number>) as Boolean {
        return a[0] == b[0] && a[1] == b[1] && a[2] == b[2];
    }

    (:test)
    function clampKeepsValidDate(logger as Logger) as Boolean {
        return sameDate(DateMath.clampDate(date(2023, 6, 12), date(2026, 10, 28)), date(2023, 6, 12))
            && sameDate(DateMath.clampDate(date(2026, 10, 28), date(2026, 10, 28)), date(2026, 10, 28));
    }

    (:test)
    function clampDayToMonthLength(logger as Logger) as Boolean {
        return sameDate(DateMath.clampDate(date(2025, 2, 31), date(2026, 10, 28)), date(2025, 2, 28))
            && sameDate(DateMath.clampDate(date(2024, 2, 30), date(2026, 10, 28)), date(2024, 2, 29))
            && sameDate(DateMath.clampDate(date(2025, 4, 31), date(2026, 10, 28)), date(2025, 4, 30));
    }

    (:test)
    function clampFutureToToday(logger as Logger) as Boolean {
        return sameDate(DateMath.clampDate(date(2026, 10, 29), date(2026, 10, 28)), date(2026, 10, 28))
            && sameDate(DateMath.clampDate(date(2026, 12, 1), date(2026, 10, 28)), date(2026, 10, 28))
            && sameDate(DateMath.clampDate(date(2026, 11, 31), date(2026, 10, 28)), date(2026, 10, 28));
    }

    // Milestones

    (:test)
    function dayMilestones(logger as Logger) as Boolean {
        return !DateMath.isDayMilestone(0)
            && DateMath.isDayMilestone(100)
            && DateMath.isDayMilestone(1000)
            && !DateMath.isDayMilestone(150)
            && !DateMath.isDayMilestone(99);
    }

    (:test)
    function anniversaries(logger as Logger) as Boolean {
        return DateMath.isAnniversary([3, 0, 0] as Array<Number>)
            && !DateMath.isAnniversary([0, 0, 0] as Array<Number>)
            && !DateMath.isAnniversary([0, 1, 0] as Array<Number>)
            && !DateMath.isAnniversary([1, 0, 1] as Array<Number>);
    }
}
