USING System.Timer;

NAMESPACE Simatic.Ax.AutomationBase
    /// Error state codes for equipment
    /// NoError: No error present (0x0000)
    /// ConfigError: Configuration error, typically Mode not assigned (0x8001)
    /// OtherError: Equipment-specific error (0x8999)
    TYPE
        ErrorState : WORD (NoError := WORD#0000, ConfigError := WORD#8001, OtherError := WORD#8999) := NoError;
    END_TYPE
END_NAMESPACE
