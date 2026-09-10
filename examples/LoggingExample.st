USING Simatic.Ax.AutomationBase;

NAMESPACE Examples

    /// Example program demonstrating the logging functionality
    PROGRAM LoggingExample
        VAR
            // Logger instances
            ringLogger : RingBufferLogger;
            consoleLogger : ConsoleLogger;
            
            // Buffer for ring buffer logger (100 entries)
            logBuffer : ARRAY[0..99] OF LogEntry;
            
            // Example variables
            temperature : REAL := 25.0;
            pressure : REAL := 1.0;
            errorOccurred : BOOL := FALSE;
            cycleCount : DINT := 0;
        END_VAR
        
        // Initialize loggers (call once at startup)
        ringLogger.Buffer := REF(logBuffer);
        ringLogger.MinLogLevel := LogLevel#Info;  // Log Info and above
        
        consoleLogger.Enabled := TRUE;
        consoleLogger.MinLogLevel := LogLevel#Debug;  // Log everything
        
        // Increment cycle counter
        cycleCount := cycleCount + 1;
        
        //=============================================================================
        // EXAMPLE 1: Simple logging
        //=============================================================================
        IF (cycleCount = 1) THEN
            ringLogger.LogInfo('System started');
            consoleLogger.LogInfo('System started');
        END_IF;
        
        //=============================================================================
        // EXAMPLE 2: Conditional logging based on values
        //=============================================================================
        IF (temperature > 80.0) THEN
            ringLogger.LogWarning('Temperature high: 85.5 degC');
        END_IF;
        
        IF (temperature > 100.0) THEN
            ringLogger.LogError('Temperature critical: 105.0 degC');
        END_IF;
        
        //=============================================================================
        // EXAMPLE 3: Logging with source information
        //=============================================================================
        IF (pressure < 0.5) THEN
            ringLogger.LogWithSource(
                level := LogLevel#Warning,
                message := 'Pressure low',
                source := 'PressureSensor1'
            );
        END_IF;
        
        //=============================================================================
        // EXAMPLE 4: Debug logging
        //=============================================================================
        IF (cycleCount MOD 1000 = 0) THEN
            consoleLogger.LogDebug('Cycle 1000 reached');
        END_IF;
        
        //=============================================================================
        // EXAMPLE 5: Checking log statistics
        //=============================================================================
        IF ringLogger.HasLevel(LogLevel#Error) THEN
            // React to errors in log
            errorOccurred := TRUE;
        END_IF;
        
        //=============================================================================
        // EXAMPLE 6: Reading log entries
        //=============================================================================
        VAR
            entry : LogEntry;
            valid : BOOL;
            i : DINT;
        END_VAR
        
        // Read last 5 entries
        FOR i := 0 TO 4 DO
            IF (i < ringLogger.GetCount()) THEN
                ringLogger.GetEntryAt(
                    index := ringLogger.GetCount() - 1 - i,
                    entry => entry,
                    valid => valid
                );
                
                IF valid THEN
                    // Process entry
                    CASE entry.Level OF
                        LogLevel#Error:
                            // Handle error entry
                            ;
                        LogLevel#Warning:
                            // Handle warning entry
                            ;
                    END_CASE;
                END_IF;
            END_IF;
        END_FOR;
        
        //=============================================================================
        // EXAMPLE 7: Log statistics
        //=============================================================================
        VAR
            totalLogs : DINT;
            errorCount : DINT;
            warningCount : DINT;
            infoCount : DINT;
        END_VAR
        
        totalLogs := ringLogger.GetCount();
        errorCount := ringLogger.GetErrorCount();
        warningCount := ringLogger.GetWarningCount();
        infoCount := ringLogger.GetInfoCount();
        
        //=============================================================================
        // EXAMPLE 8: Clearing logs
        //=============================================================================
        VAR
            clearLogs : BOOL := FALSE;
        END_VAR
        
        IF clearLogs THEN
            ringLogger.Clear();
            consoleLogger.Clear();
            clearLogs := FALSE;
        END_IF;
        
    END_PROGRAM

END_NAMESPACE
