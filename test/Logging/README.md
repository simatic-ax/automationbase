# Logging Module Tests

## Overview

Comprehensive test suite for the Logging module, covering all functionality of RingBufferLogger, ConsoleLogger, and integration scenarios.

## Test Files

### 1. RingBufferLoggerTest.st
Tests for the RingBufferLogger class with external buffer management.

**Test Categories:**
- **Basic Logging Tests**: Verify each log level increments counters correctly
- **Ring Buffer Tests**: Test circular buffer behavior and overflow handling
- **Log Level Filtering Tests**: Verify MinLogLevel filtering works correctly
- **HasLevel Tests**: Test detection of specific log levels
- **Clear Tests**: Verify clearing resets all state
- **Log With Source Tests**: Test source information storage
- **Buffer Size Tests**: Verify buffer size calculation
- **NULL Buffer Tests**: Ensure graceful handling of uninitialized buffer

**Key Tests:**
- `LogInfo_IncreasesCount`: Basic info logging
- `RingBuffer_OverwritesOldestEntry`: Circular buffer behavior
- `GetEntryAt_ReturnsCorrectEntry`: Entry retrieval
- `MinLogLevel_Info_FiltersDebug`: Log level filtering
- `NullBuffer_DoesNotCrash`: NULL safety

### 2. ConsoleLoggerTest.st
Tests for the ConsoleLogger class (lightweight logger without storage).

**Test Categories:**
- **Basic Logging Tests**: Verify logging increments counters
- **Enabled/Disabled Tests**: Test enable/disable functionality
- **Log Level Filtering Tests**: Verify MinLogLevel filtering
- **HasLevel Tests**: Test level detection
- **Clear Tests**: Verify counter reset
- **Combined Tests**: Test multiple features together

**Key Tests:**
- `Disabled_DoesNotLog`: Verify disabled logger doesn't log
- `MinLogLevel_Warning_FiltersInfoAndDebug`: Multi-level filtering
- `EnabledAndFiltered_LogsOnlyFiltered`: Combined feature test

### 3. LoggingIntegrationTest.st
Integration tests simulating realistic usage scenarios.

**Test Categories:**
- **Multi-Logger Tests**: Multiple loggers working independently
- **Realistic Scenario Tests**: Real-world usage patterns
- **Clear and Restart Tests**: Batch processing scenarios
- **Edge Case Tests**: Boundary conditions and error cases

**Key Tests:**
- `TwoLoggers_DifferentFiltering`: Independent logger configuration
- `SystemStartup_LogsCorrectly`: Startup sequence simulation
- `ErrorScenario_LogsWarningThenError`: Error escalation
- `LongRunning_FillsBuffer`: Buffer overflow handling
- `ClearBetweenBatches_WorksCorrectly`: Batch processing

## Running the Tests

### Using APAX

```bash
# Run all tests
apax test

# Run with coverage (LLVM engine only)
apax test --coverage

# Run specific test file
apax test --filter "RingBufferLoggerTest"
```

### Test Configuration

Tests use small buffers (10 entries) for faster execution and easier verification:

```st
VAR
    logBuffer : ARRAY[0..9] OF LogEntry;  // 10 entries for testing
END_VAR
```

## Test Patterns

### Stateless Testing Pattern

All tests use the stateless pattern to ensure test isolation:

```st
VAR
    logger, loggerStateless : RingBufferLogger;
    logBuffer, logBufferStateless : ARRAY[0..9] OF LogEntry;
END_VAR

{TestSetup}
METHOD PUBLIC TestSetup
    logger := loggerStateless;
    logBuffer := logBufferStateless;
    logger.Buffer := REF(logBuffer);
END_METHOD
```

### Testing Log Levels

Since ENUMs can't be directly converted to DINT, we compare directly:

```st
Equal(expected := TRUE, actual := entry.Level = LogLevel#Info);
```

### Testing NULL Safety

```st
{Test}
METHOD PUBLIC NullBuffer_DoesNotCrash
    testLogger.LogInfo('Test');
    Equal(expected := 0, actual := testLogger.GetCount());
END_METHOD
```

## Test Coverage

### RingBufferLogger Coverage
- ✅ All log methods (LogInfo, LogWarning, LogError, LogDebug)
- ✅ Log with source information
- ✅ Ring buffer overflow behavior
- ✅ Entry retrieval by index
- ✅ Log level filtering (all combinations)
- ✅ HasLevel detection
- ✅ Clear functionality
- ✅ Buffer size calculation
- ✅ NULL buffer handling
- ✅ Counter accuracy

### ConsoleLogger Coverage
- ✅ All log methods
- ✅ Enable/disable functionality
- ✅ Log level filtering
- ✅ HasLevel detection
- ✅ Clear functionality
- ✅ Combined features

### Integration Test Coverage
- ✅ Multiple logger independence
- ✅ Different filtering per logger
- ✅ Realistic startup sequence
- ✅ Error escalation scenarios
- ✅ Long-running operations
- ✅ Batch processing with clear
- ✅ Edge cases (empty, negative index)

## Expected Test Results

All tests should pass:

```
✓ RingBufferLoggerTest: 20/20 tests passed
✓ ConsoleLoggerTest: 15/15 tests passed
✓ LoggingIntegrationTest: 10/10 tests passed

Total: 45/45 tests passed
```

## Common Test Failures

### Buffer Not Initialized
**Symptom**: Tests crash or fail with NULL reference
**Solution**: Ensure `logger.Buffer := REF(logBuffer)` in TestSetup

### Wrong Count
**Symptom**: GetCount() returns unexpected value
**Solution**: Check MinLogLevel filtering - some messages may be filtered out

### Entry Level Mismatch
**Symptom**: Retrieved entry has wrong level
**Solution**: Verify ring buffer index calculation, especially after overflow

## Adding New Tests

### Template for New Test

```st
{Test}
METHOD PUBLIC YourTestName
    VAR
        // Local test variables
    END_VAR
    
    // Arrange
    logger.MinLogLevel := LogLevel#Info;
    
    // Act
    logger.LogInfo('Test message');
    
    // Assert
    Equal(expected := 1, actual := logger.GetCount());
END_METHOD
```

### Best Practices

1. **Use descriptive test names**: `MinLogLevel_Warning_FiltersInfoAndDebug`
2. **Follow AAA pattern**: Arrange, Act, Assert
3. **Test one thing**: Each test should verify one specific behavior
4. **Use small buffers**: Faster execution and easier verification
5. **Clean state**: Use TestSetup to ensure clean state
6. **Test edge cases**: NULL, empty, overflow, negative values

## See Also

- [Logging Module Documentation](../../src/Logging/README.md)
- [Logging Example](../../examples/LoggingExample.st)
- [AxUnit Documentation](https://github.com/simatic-ax/axunit)
