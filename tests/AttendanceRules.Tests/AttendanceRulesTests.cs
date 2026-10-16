using SchoolNet.Attendance;

public class AttendanceRulesTests
{
    [Fact]
    public void ThreeLatesMakeOneAbsent()
    {
        Assert.Equal(1, AttendanceRules.AbsentsFromLates(3));
    }

    [Fact]
    public void TwoLatesMakeNoAbsent()
    {
        Assert.Equal(0, AttendanceRules.AbsentsFromLates(2));
    }
}
