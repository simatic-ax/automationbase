USING Siemens.Simatic.Clocks;

NAMESPACE Simatic.Ax.AutomationBase

    /// Ring buffer logger implementation
    /// Stores log entries in a circular buffer with configurable size
    /// When buffer is full, oldest entries are overwritten
    CLASS RingBufferLogger IMPLEMENTS ILogger
        
        VAR PUBLIC
            /// Reference to external buffer array
            Buffer : REF_TO ARRAY[*] OF LogEntry;
            
            /// Minimum log level to record (filters out lower priority messages)
            MinLogLevel : LogLevel := LogLevel#Info;
        END_VAR
        
        VAR PRIVATE
            /// Current write position in buffer
            _writeIndex : DINT := 0;
            
            /// Total number of entries written (can exceed buffer size)
            _totalCount : DINT := 0;
            
            /// Number of entries currently in buffer
            _currentCount : DINT := 0;
            
            /// Counters for each log level
            _infoCount : DINT := 0;
            _warningCount : DINT := 0;
            _errorCount : DINT := 0;
            _debugCount : DINT := 0;
            
            /// Cached buffer size
            _bufferSize : DINT := 0;
        END_VAR
        
        /// Logs a message with specified level
        METHOD PUBLIC Log
            VAR_INPUT
                level : LogLevel;
                message : STRING[254];
            END_VAR
            VAR_TEMP
                entry : LogEntry;
            END_VAR
            
            // Check if buffer is configured
            IF Buffer = NULL THEN
                RETURN;
            END_IF;
            
            // Filter based on minimum log level
            IF NOT THIS.ShouldLog(level) THEN
                RETURN;
            END_IF;
            
            // Create log entry with timestamp
            entry.Level := level;
            entry.Message := message;
            entry.Timestamp := GetCurrentTimestamp();
            entry.Code := DWORD#0;
            
            // Store in ring buffer
            THIS.AddEntry(entry);
        END_METHOD
        
        /// Logs a message with source information
        METHOD PUBLIC LogWithSource
            VAR_INPUT
                level : LogLevel;
                message : STRING[254];
                source : STRING[80];
            END_VAR
            VAR_TEMP
                entry : LogEntry;
            END_VAR
            
            IF Buffer = NULL THEN
                RETURN;
            END_IF;
            
            IF NOT THIS.ShouldLog(level) THEN
                RETURN;
            END_IF;
            
            entry.Level := level;
            entry.Message := message;
            entry.Timestamp := GetCurrentTimestamp();
            entry.Source := source;
            entry.Code := DWORD#0;
            
            THIS.AddEntry(entry);
        END_METHOD
        
        /// Logs an informational message
        METHOD PUBLIC LogInfo
            VAR_INPUT
                message : STRING[254];
            END_VAR
            THIS.Log(level := LogLevel#Info, message := message);
        END_METHOD
        
        /// Logs a warning message
        METHOD PUBLIC LogWarning
            VAR_INPUT
                message : STRING[254];
            END_VAR
            THIS.Log(level := LogLevel#Warning, message := message);
        END_METHOD
        
        /// Logs an error message
        METHOD PUBLIC LogError
            VAR_INPUT
                message : STRING[254];
            END_VAR
            THIS.Log(level := LogLevel#Error, message := message);
        END_METHOD
        
        /// Logs a debug message
        METHOD PUBLIC LogDebug
            VAR_INPUT
                message : STRING[254];
            END_VAR
            THIS.Log(level := LogLevel#Debug, message := message);
        END_METHOD
        
        /// Clears all log entries
        METHOD PUBLIC Clear
            _writeIndex := 0;
            _totalCount := 0;
            _currentCount := 0;
            _infoCount := 0;
            _warningCount := 0;
            _errorCount := 0;
            _debugCount := 0;
        END_METHOD
        
        /// Returns the number of log entries currently stored
        METHOD PUBLIC GetCount : DINT
            GetCount := _currentCount;
        END_METHOD
        
        /// Checks if logger has entries of specified level
        METHOD PUBLIC HasLevel : BOOL
            VAR_INPUT
                level : LogLevel;
            END_VAR
            CASE level OF
                LogLevel#Info:
                    HasLevel := (_infoCount > 0);
                LogLevel#Warning:
                    HasLevel := (_warningCount > 0);
                LogLevel#Error:
                    HasLevel := (_errorCount > 0);
                LogLevel#Debug:
                    HasLevel := (_debugCount > 0);
            END_CASE;
        END_METHOD
        
        /// Returns a log entry at specified index (0 = oldest, GetCount-1 = newest)
        METHOD PUBLIC GetEntryAt
            VAR_INPUT
                index : DINT;
            END_VAR
            VAR_OUTPUT
                entry : LogEntry;
                valid : BOOL;
            END_VAR
            VAR_TEMP
                actualIndex : DINT;
            END_VAR
            
            valid := FALSE;
            
            IF Buffer = NULL THEN
                RETURN;
            END_IF;
            
            IF (index < 0) OR (index >= _currentCount) THEN
                RETURN;
            END_IF;
            
            // Update buffer size if needed
            IF (_bufferSize = 0) THEN
                _bufferSize := UPPER_BOUND(Buffer^, 1) - LOWER_BOUND(Buffer^, 1) + 1;
            END_IF;
            
            // Calculate actual buffer index
            IF (_currentCount < _bufferSize) THEN
                // Buffer not yet full, entries start at 0
                actualIndex := LOWER_BOUND(Buffer^, 1) + index;
            ELSE
                // Buffer is full, calculate from write position
                actualIndex := LOWER_BOUND(Buffer^, 1) + ((_writeIndex + index) MOD _bufferSize);
            END_IF;
            
            entry := Buffer^[actualIndex];
            valid := TRUE;
        END_METHOD
        
        /// Returns the number of info messages
        METHOD PUBLIC GetInfoCount : DINT
            GetInfoCount := _infoCount;
        END_METHOD
        
        /// Returns the number of warning messages
        METHOD PUBLIC GetWarningCount : DINT
            GetWarningCount := _warningCount;
        END_METHOD
        
        /// Returns the number of error messages
        METHOD PUBLIC GetErrorCount : DINT
            GetErrorCount := _errorCount;
        END_METHOD
        
        /// Returns the number of debug messages
        METHOD PUBLIC GetDebugCount : DINT
            GetDebugCount := _debugCount;
        END_METHOD
        
        /// Returns the buffer size
        METHOD PUBLIC GetBufferSize : DINT
            IF Buffer = NULL THEN
                GetBufferSize := 0;
                RETURN;
            END_IF;
            
            IF (_bufferSize = 0) THEN
                _bufferSize := UPPER_BOUND(Buffer^, 1) - LOWER_BOUND(Buffer^, 1) + 1;
            END_IF;
            
            GetBufferSize := _bufferSize;
        END_METHOD
        
        /// Checks if a message with given level should be logged
        METHOD PRIVATE ShouldLog : BOOL
            VAR_INPUT
                level : LogLevel;
            END_VAR
            
            // Debug < Info < Warning < Error
            CASE MinLogLevel OF
                LogLevel#Debug:
                    ShouldLog := TRUE;  // Log everything
                LogLevel#Info:
                    ShouldLog := (level <> LogLevel#Debug);
                LogLevel#Warning:
                    ShouldLog := (level = LogLevel#Warning) OR (level = LogLevel#Error);
                LogLevel#Error:
                    ShouldLog := (level = LogLevel#Error);
            END_CASE;
        END_METHOD
        
        /// Adds an entry to the ring buffer
        METHOD PRIVATE AddEntry
            VAR_INPUT
                entry : LogEntry;
            END_VAR
            VAR_TEMP
                bufferIndex : DINT;
            END_VAR
            
            IF Buffer = NULL THEN
                RETURN;
            END_IF;
            
            // Update buffer size if needed
            IF (_bufferSize = 0) THEN
                _bufferSize := UPPER_BOUND(Buffer^, 1) - LOWER_BOUND(Buffer^, 1) + 1;
            END_IF;
            
            // Calculate actual buffer index
            bufferIndex := LOWER_BOUND(Buffer^, 1) + _writeIndex;
            
            // Store entry in buffer
            Buffer^[bufferIndex] := entry;
            
            // Update counters based on level
            CASE entry.Level OF
                LogLevel#Info:
                    _infoCount := _infoCount + 1;
                LogLevel#Warning:
                    _warningCount := _warningCount + 1;
                LogLevel#Error:
                    _errorCount := _errorCount + 1;
                LogLevel#Debug:
                    _debugCount := _debugCount + 1;
            END_CASE;
            
            // Update write index (circular)
            _writeIndex := (_writeIndex + 1) MOD _bufferSize;
            
            // Update counts
            _totalCount := _totalCount + 1;
            IF (_currentCount < _bufferSize) THEN
                _currentCount := _currentCount + 1;
            END_IF;
        END_METHOD
        
    END_CLASS

END_NAMESPACE
