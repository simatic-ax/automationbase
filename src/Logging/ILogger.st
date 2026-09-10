NAMESPACE Simatic.Ax.AutomationBase

    /// Interface for logger implementations
    /// Allows different logging backends (console, file, network, etc.)
    INTERFACE ILogger
        
        /// Logs a message with specified level
        METHOD Log
            VAR_INPUT
                level : LogLevel;
                message : STRING[254];
            END_VAR
        END_METHOD
        
        /// Logs an informational message
        METHOD LogInfo
            VAR_INPUT
                message : STRING[254];
            END_VAR
        END_METHOD
        
        /// Logs a warning message
        METHOD LogWarning
            VAR_INPUT
                message : STRING[254];
            END_VAR
        END_METHOD
        
        /// Logs an error message
        METHOD LogError
            VAR_INPUT
                message : STRING[254];
            END_VAR
        END_METHOD
        
        /// Logs a debug message
        METHOD LogDebug
            VAR_INPUT
                message : STRING[254];
            END_VAR
        END_METHOD
        
        /// Clears all log entries
        METHOD Clear
        END_METHOD
        
        /// Returns the number of log entries
        METHOD GetCount : DINT
        END_METHOD
        
        /// Checks if logger has entries of specified level
        METHOD HasLevel : BOOL
            VAR_INPUT
                level : LogLevel;
            END_VAR
        END_METHOD
        
    END_INTERFACE

END_NAMESPACE
