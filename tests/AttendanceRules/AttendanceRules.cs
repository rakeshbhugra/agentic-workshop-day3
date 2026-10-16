namespace SchoolNet.Attendance;

public static class AttendanceRules
{
    // School rule: 3 late marks in one week count as 1 absent.
    public static int AbsentsFromLates(int lates)
    {
        return lates / 3;
    }
}
