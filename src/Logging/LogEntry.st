NAMESPACE Simatic.Ax.AutomationBase

    /// Represents a single log entry
    TYPE
        LogEntry : STRUCT
            /// Log level of this entry
            Level : LogLevel;
            
            /// Log message text
            Message : STRING[254];
            
            /// Timestamp when the log entry was created
            Timestamp : LDATE_AND_TIME;
            
            /// Optional: Source/Component that generated the log
            Source : STRING[80];
            
            /// Optional: Error code or additional identifier
            Code : DWORD;
        END_STRUCT;
    END_TYPE

END_NAMESPACE
