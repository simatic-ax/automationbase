USING System.DateTime;

NAMESPACE Simatic.Ax.Mocks

    /// Mock for GetCurrentTimestamp that returns a fixed timestamp
    FUNCTION GetCurrentTimestamp : LDATE_AND_TIME
        // Return a fixed timestamp for testing: 2024-01-15 10:30:45
        GetCurrentTimestamp := LDATE_AND_TIME#2024-01-15-10:30:45;
    END_FUNCTION

END_NAMESPACE
