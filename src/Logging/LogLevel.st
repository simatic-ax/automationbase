NAMESPACE Simatic.Ax.AutomationBase

    /// Enumeration of log levels
    /// Defines the severity of log messages
    TYPE
        LogLevel : (
            Info,       // Informational messages
            Warning,    // Warning messages - potential issues
            Error,      // Error messages - something went wrong
            Debug       // Debug messages - detailed diagnostic information
        ) := Info;
    END_TYPE

END_NAMESPACE
