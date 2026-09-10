USING Siemens.Simatic.Clocks;

NAMESPACE Simatic.Ax.AutomationBase

    /// Wrapper function for getting system time
    /// This allows mocking in tests
    /// Uses the global GetSystemDateTime function
    FUNCTION GetCurrentTimestamp : LDATE_AND_TIME
        VAR_TEMP
            systemDateTime : LDATE_AND_TIME;
        END_VAR
        
        GetSystemDateTime(value => systemDateTime);
        GetCurrentTimestamp := systemDateTime;
    END_FUNCTION

END_NAMESPACE
