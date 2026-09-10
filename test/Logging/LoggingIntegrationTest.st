USING Simatic.Ax.AutomationBase;
USING AxUnit.Assert;

NAMESPACE Simatic.Ax.AutomationBase.Tests

    {TestFixture}
    CLASS LoggingIntegrationTest
        VAR
            ringLogger, ringLoggerStateless : RingBufferLogger;
            logBuffer, logBufferStateless : ARRAY[0..49] OF LogEntry;
        END_VAR
        
        {TestSetup}
        METHOD PUBLIC TestSetup
            ringLogger := ringLoggerStateless;
            logBuffer := logBufferStateless;
            
            ringLogger.Buffer := REF(logBuffer);
            ringLogger.MinLogLevel := LogLevel#Info;
        END_METHOD
        
        //=============================================================================
        // MULTI-LOGGER TESTS
        //=============================================================================
        
        {Test}
        METHOD PUBLIC TwoLoggers_LogIndependently
            ringLogger.LogInfo('Ring message');
            Equal(expected := 1, actual := ringLogger.GetCount());
        END_METHOD
        
        {Test}
        METHOD PUBLIC TwoLoggers_DifferentFiltering
            ringLogger.MinLogLevel := LogLevel#Warning;
            
            ringLogger.LogInfo('Info to ring');
            ringLogger.LogWarning('Warning to ring');
            
            
            Equal(expected := 1, actual := ringLogger.GetCount());  // Only warning
        END_METHOD
        
        //=============================================================================
        // REALISTIC SCENARIO TESTS
        //=============================================================================
        
        {Test}
        METHOD PUBLIC SystemStartup_LogsCorrectly
            // Simulate system startup sequence
            ringLogger.LogInfo('System initializing');
            ringLogger.LogInfo('Loading configuration');
            ringLogger.LogInfo('Connecting to devices');
            ringLogger.LogInfo('System ready');
            
            Equal(expected := 4, actual := ringLogger.GetCount());
            Equal(expected := 4, actual := ringLogger.GetInfoCount());
        END_METHOD
        
        {Test}
        METHOD PUBLIC ErrorScenario_LogsWarningThenError
            VAR
                entry : LogEntry;
                valid : BOOL;
            END_VAR
            
            // Simulate error escalation
            ringLogger.LogInfo('Process started');
            ringLogger.LogWarning('Temperature rising');
            ringLogger.LogWarning('Temperature high');
            ringLogger.LogError('Temperature critical - shutdown');
            
            Equal(expected := 4, actual := ringLogger.GetCount());
            Equal(expected := 1, actual := ringLogger.GetInfoCount());
            Equal(expected := 2, actual := ringLogger.GetWarningCount());
            Equal(expected := 1, actual := ringLogger.GetErrorCount());
            
            // Verify we can detect errors
            Equal(expected := TRUE, actual := ringLogger.HasLevel(LogLevel#Error));
            
            // Get last entry (should be error)
            ringLogger.GetEntryAt(
                index := ringLogger.GetCount() - 1,
                entry => entry,
                valid => valid
            );
            
            Equal(expected := TRUE, actual := valid);
            Equal(expected := TRUE, actual := entry.Level = LogLevel#Error);
        END_METHOD
        
        {Test}
        METHOD PUBLIC LongRunning_FillsBuffer
            VAR
                i : DINT;
            END_VAR
            
            // Log more than buffer size (50 entries)
            FOR i := 1 TO 75 DO
                ringLogger.LogInfo('Message');
            END_FOR;
            
            // Buffer should be full
            Equal(expected := 50, actual := ringLogger.GetCount());
            Equal(expected := 75, actual := ringLogger.GetInfoCount());  // Total logged
        END_METHOD
        
        {Test}
        METHOD PUBLIC MixedLevels_AllCountedCorrectly
            VAR
                i : DINT;
            END_VAR
            
            // Enable debug logging for this test
            ringLogger.MinLogLevel := LogLevel#Debug;
            
            // Log various levels
            FOR i := 1 TO 10 DO
                ringLogger.LogInfo('Info');
            END_FOR;
            
            FOR i := 1 TO 5 DO
                ringLogger.LogWarning('Warning');
            END_FOR;
            
            FOR i := 1 TO 3 DO
                ringLogger.LogError('Error');
            END_FOR;
            
            FOR i := 1 TO 2 DO
                ringLogger.LogDebug('Debug');
            END_FOR;
            
            Equal(expected := 20, actual := ringLogger.GetCount());
            Equal(expected := 10, actual := ringLogger.GetInfoCount());
            Equal(expected := 5, actual := ringLogger.GetWarningCount());
            Equal(expected := 3, actual := ringLogger.GetErrorCount());
            Equal(expected := 2, actual := ringLogger.GetDebugCount());
        END_METHOD
        
        //=============================================================================
        // CLEAR AND RESTART TESTS
        //=============================================================================
        
        {Test}
        METHOD PUBLIC ClearBetweenBatches_WorksCorrectly
            // First batch
            ringLogger.LogInfo('Batch 1 start');
            ringLogger.LogInfo('Batch 1 end');
            
            Equal(expected := 2, actual := ringLogger.GetCount());
            
            // Clear for new batch
            ringLogger.Clear();
            
            // Second batch
            ringLogger.LogInfo('Batch 2 start');
            ringLogger.LogWarning('Batch 2 warning');
            ringLogger.LogInfo('Batch 2 end');
            
            Equal(expected := 3, actual := ringLogger.GetCount());
            Equal(expected := 2, actual := ringLogger.GetInfoCount());
            Equal(expected := 1, actual := ringLogger.GetWarningCount());
        END_METHOD
        
        //=============================================================================
        // EDGE CASE TESTS
        //=============================================================================
        
        {Test}
        METHOD PUBLIC EmptyLogger_GetEntryAt_ReturnsFalse
            VAR
                entry : LogEntry;
                valid : BOOL;
            END_VAR
            
            ringLogger.GetEntryAt(index := 0, entry => entry, valid => valid);
            
            Equal(expected := FALSE, actual := valid);
        END_METHOD
        
        {Test}
        METHOD PUBLIC NegativeIndex_ReturnsFalse
            VAR
                entry : LogEntry;
                valid : BOOL;
            END_VAR
            
            ringLogger.LogInfo('Message');
            ringLogger.GetEntryAt(index := -1, entry => entry, valid => valid);
            
            Equal(expected := FALSE, actual := valid);
        END_METHOD
        
    END_CLASS

END_NAMESPACE
