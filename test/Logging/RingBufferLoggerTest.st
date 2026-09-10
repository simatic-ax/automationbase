USING Simatic.Ax.AutomationBase;
USING AxUnit.Assert;

NAMESPACE Simatic.Ax.AutomationBase.Tests

    {TestFixture}
    CLASS RingBufferLoggerTest
        VAR
            logger, loggerStateless : RingBufferLogger;
            logBuffer, logBufferStateless : ARRAY[0..9] OF LogEntry;  // Small buffer for testing
            testLogger : RingBufferLogger;  // For NULL buffer test
        END_VAR
        
        {TestSetup}
        METHOD PUBLIC TestSetup
            logger := loggerStateless;
            logBuffer := logBufferStateless;
            logger.Buffer := REF(logBuffer);
            logger.MinLogLevel := LogLevel#Debug;  // Log everything
        END_METHOD
        
        //=============================================================================
        // BASIC LOGGING TESTS
        //=============================================================================
        
        {Test}
        METHOD PUBLIC LogInfo_IncreasesCount
            logger.LogInfo('Test info message');
            
            Equal(expected := 1, actual := logger.GetCount());
            Equal(expected := 1, actual := logger.GetInfoCount());
        END_METHOD
        
        {Test}
        METHOD PUBLIC LogWarning_IncreasesCount
            logger.LogWarning('Test warning message');
            
            Equal(expected := 1, actual := logger.GetCount());
            Equal(expected := 1, actual := logger.GetWarningCount());
        END_METHOD
        
        {Test}
        METHOD PUBLIC LogError_IncreasesCount
            logger.LogError('Test error message');
            
            Equal(expected := 1, actual := logger.GetCount());
            Equal(expected := 1, actual := logger.GetErrorCount());
        END_METHOD
        
        {Test}
        METHOD PUBLIC LogDebug_IncreasesCount
            logger.LogDebug('Test debug message');
            
            Equal(expected := 1, actual := logger.GetCount());
            Equal(expected := 1, actual := logger.GetDebugCount());
        END_METHOD
        
        {Test}
        METHOD PUBLIC MultipleLogs_CountsCorrectly
            logger.LogInfo('Info 1');
            logger.LogInfo('Info 2');
            logger.LogWarning('Warning 1');
            logger.LogError('Error 1');
            logger.LogDebug('Debug 1');
            
            Equal(expected := 5, actual := logger.GetCount());
            Equal(expected := 2, actual := logger.GetInfoCount());
            Equal(expected := 1, actual := logger.GetWarningCount());
            Equal(expected := 1, actual := logger.GetErrorCount());
            Equal(expected := 1, actual := logger.GetDebugCount());
        END_METHOD
        
        //=============================================================================
        // RING BUFFER TESTS
        //=============================================================================
        
        {Test}
        METHOD PUBLIC RingBuffer_OverwritesOldestEntry
            VAR
                i : DINT;
                entry : LogEntry;
                valid : BOOL;
            END_VAR
            
            // Fill buffer (10 entries)
            FOR i := 0 TO 9 DO
                logger.LogInfo('Message');
            END_FOR;
            
            Equal(expected := 10, actual := logger.GetCount());
            
            // Add one more (should overwrite oldest)
            logger.LogInfo('New message');
            
            Equal(expected := 10, actual := logger.GetCount());  // Still 10
            Equal(expected := 11, actual := logger.GetInfoCount());  // But 11 total logged
        END_METHOD
        
        {Test}
        METHOD PUBLIC GetEntryAt_ReturnsCorrectEntry
            VAR
                entry : LogEntry;
                valid : BOOL;
            END_VAR
            
            logger.LogInfo('First message');
            logger.LogWarning('Second message');
            logger.LogError('Third message');
            
            // Get first entry
            logger.GetEntryAt(index := 0, entry => entry, valid => valid);
            
            Equal(expected := TRUE, actual := valid);
            Equal(expected := TRUE, actual := entry.Level = LogLevel#Info);
            
            // Get second entry
            logger.GetEntryAt(index := 1, entry => entry, valid => valid);
            
            Equal(expected := TRUE, actual := valid);
            Equal(expected := TRUE, actual := entry.Level = LogLevel#Warning);
        END_METHOD
        
        {Test}
        METHOD PUBLIC GetEntryAt_InvalidIndex_ReturnsFalse
            VAR
                entry : LogEntry;
                valid : BOOL;
            END_VAR
            
            logger.LogInfo('Message');
            
            // Try to get entry beyond count
            logger.GetEntryAt(index := 5, entry => entry, valid => valid);
            
            Equal(expected := FALSE, actual := valid);
        END_METHOD
        
        //=============================================================================
        // LOG LEVEL FILTERING TESTS
        //=============================================================================
        
        {Test}
        METHOD PUBLIC MinLogLevel_Info_FiltersDebug
            logger.MinLogLevel := LogLevel#Info;
            
            logger.LogDebug('Debug message');
            logger.LogInfo('Info message');
            logger.LogWarning('Warning message');
            
            Equal(expected := 2, actual := logger.GetCount());  // Only Info and Warning
            Equal(expected := 0, actual := logger.GetDebugCount());
            Equal(expected := 1, actual := logger.GetInfoCount());
        END_METHOD
        
        {Test}
        METHOD PUBLIC MinLogLevel_Warning_FiltersInfoAndDebug
            logger.MinLogLevel := LogLevel#Warning;
            
            logger.LogDebug('Debug message');
            logger.LogInfo('Info message');
            logger.LogWarning('Warning message');
            logger.LogError('Error message');
            
            Equal(expected := 2, actual := logger.GetCount());  // Only Warning and Error
            Equal(expected := 0, actual := logger.GetDebugCount());
            Equal(expected := 0, actual := logger.GetInfoCount());
            Equal(expected := 1, actual := logger.GetWarningCount());
            Equal(expected := 1, actual := logger.GetErrorCount());
        END_METHOD
        
        {Test}
        METHOD PUBLIC MinLogLevel_Error_OnlyLogsErrors
            logger.MinLogLevel := LogLevel#Error;
            
            logger.LogDebug('Debug message');
            logger.LogInfo('Info message');
            logger.LogWarning('Warning message');
            logger.LogError('Error message');
            
            Equal(expected := 1, actual := logger.GetCount());
            Equal(expected := 1, actual := logger.GetErrorCount());
        END_METHOD
        
        //=============================================================================
        // HASLEVEL TESTS
        //=============================================================================
        
        {Test}
        METHOD PUBLIC HasLevel_ReturnsTrue_WhenLevelExists
            logger.LogError('Error message');
            
            Equal(expected := TRUE, actual := logger.HasLevel(LogLevel#Error));
            Equal(expected := FALSE, actual := logger.HasLevel(LogLevel#Warning));
        END_METHOD
        
        {Test}
        METHOD PUBLIC HasLevel_ReturnsFalse_WhenEmpty
            Equal(expected := FALSE, actual := logger.HasLevel(LogLevel#Info));
            Equal(expected := FALSE, actual := logger.HasLevel(LogLevel#Error));
        END_METHOD
        
        //=============================================================================
        // CLEAR TESTS
        //=============================================================================
        
        {Test}
        METHOD PUBLIC Clear_ResetsAllCounters
            logger.LogInfo('Info');
            logger.LogWarning('Warning');
            logger.LogError('Error');
            
            logger.Clear();
            
            Equal(expected := 0, actual := logger.GetCount());
            Equal(expected := 0, actual := logger.GetInfoCount());
            Equal(expected := 0, actual := logger.GetWarningCount());
            Equal(expected := 0, actual := logger.GetErrorCount());
            Equal(expected := 0, actual := logger.GetDebugCount());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Clear_AllowsNewLogging
            logger.LogInfo('Before clear');
            logger.Clear();
            logger.LogInfo('After clear');
            
            Equal(expected := 1, actual := logger.GetCount());
        END_METHOD
        
        //=============================================================================
        // LOG WITH SOURCE TESTS
        //=============================================================================
        
        {Test}
        METHOD PUBLIC LogWithSource_StoresSourceInformation
            VAR
                entry : LogEntry;
                valid : BOOL;
            END_VAR
            
            logger.LogWithSource(
                level := LogLevel#Error,
                message := 'Test message',
                source := 'TestSource'
            );
            
            logger.GetEntryAt(index := 0, entry => entry, valid => valid);
            
            Equal(expected := TRUE, actual := valid);
            Equal(expected := TRUE, actual := entry.Level = LogLevel#Error);
        END_METHOD
        
        //=============================================================================
        // BUFFER SIZE TESTS
        //=============================================================================
        
        {Test}
        METHOD PUBLIC GetBufferSize_ReturnsCorrectSize
            VAR
                size : DINT;
            END_VAR
            
            size := logger.GetBufferSize();
            
            Equal(expected := 10, actual := size);  // Buffer is ARRAY[0..9]
        END_METHOD
        
        {Test}
        METHOD PUBLIC NullBuffer_DoesNotCrash
            // Test that logger handles NULL buffer gracefully
            // testLogger is declared as instance variable
            // Don't assign buffer - should not crash
            testLogger.LogInfo('Test');
            
            Equal(expected := 0, actual := testLogger.GetCount());
        END_METHOD
        
    END_CLASS

END_NAMESPACE
