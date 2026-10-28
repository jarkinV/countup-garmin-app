import Toybox.Lang;

// Display text for counts and dates. English only (the app's single language),
// kept in code rather than resources so the glance can use it and tests can check it.
(:glance)
module Format {

    const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"] as Array<String>;

    // "day" or "days", the label under the big number
    function dayUnit(days as Number) as String {
        return days == 1 ? "day" : "days";
    }

    // "1234 days", the glance line
    function dayCount(days as Number) as String {
        return days + " " + dayUnit(days);
    }

    // "3y 4m 17d"
    function ymd(ymd as Array<Number>) as String {
        return ymd[0] + "y " + ymd[1] + "m " + ymd[2] + "d";
    }

    // "12 Jun 2023"
    function date(date as Array<Number>) as String {
        return date[2] + " " + MONTHS[date[1] - 1] + " " + date[0];
    }

    function monthName(month as Number) as String {
        return MONTHS[month - 1];
    }

    // "3 years!" on an anniversary, "1000 days!" on a day milestone, otherwise null.
    // An anniversary wins when both fall on the same day
    function milestone(days as Number, ymd as Array<Number>) as String? {
        if (DateMath.isAnniversary(ymd)) {
            return ymd[0] + (ymd[0] == 1 ? " year!" : " years!");
        }
        if (DateMath.isDayMilestone(days)) {
            return days + " days!";
        }
        return null;
    }
}
