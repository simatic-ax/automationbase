# EquipmentBase Tests

This document describes the comprehensive test suite created for the [`EquipmentBase`](../src/Equipment/EquipmentBase.st) class.

## Test Files Created

1. **[`test/Equipment/EquipmentBaseTest.st`](EquipmentBaseTest.st)** - Main test suite with 25 test cases
2. **[`test/mocks/MockingEquipmentBase.st`](../mocks/MockingEquipmentBase.st)** - Concrete implementation for testing
3. **[`test/mocks/MockingAutoStartup.st`](../mocks/MockingAutoStartup.st)** - Mock for ItfAutoStartup interface
4. **[`test/Equipment/StartUpStatusAssert.st`](StartUpStatusAssert.st)** - Custom assertion for StartUpStatus enum

## Test Coverage

### Initialization Tests (6 tests)
- ✅ `Init_Calls_InitUser` - Verifies InitUser is called during initialization
- ✅ `Init_Sets_IsInitialized_Flag` - Ensures initialization only happens once
- ✅ `Init_Without_Mode_Sets_ConfigError` - Tests error handling when Mode is NULL
- ✅ `Init_With_ExternalAutoStartup_Uses_External` - Verifies external auto startup is used when provided
- ✅ `Init_Without_ExternalAutoStartup_Uses_Default` - Verifies default auto startup is used when external is NULL
- ✅ `Init_With_ExternalRelease_Configures_DefaultAutoStartup` - Tests release configuration

### RunCyclic Tests (5 tests)
- ✅ `RunCyclic_Calls_Init_On_First_Call` - Ensures automatic initialization on first cycle
- ✅ `RunCyclic_Calls_RunCyclicUserCode` - Verifies user code is executed
- ✅ `RunCyclic_Does_Not_Call_UserCode_On_ConfigError` - Tests error state prevents execution
- ✅ `RunCyclic_Multiple_Calls_Only_Init_Once` - Verifies initialization happens only once
- ✅ `RunCyclic_Multiple_Calls_Execute_UserCode_Multiple_Times` - Ensures user code runs every cycle

### Error Handling Tests (4 tests)
- ✅ `HasError_Returns_False_Initially` - Tests initial error state
- ✅ `HasError_Returns_True_After_SetError` - Verifies error detection
- ✅ `SetError_Sets_Error_State` - Tests error state setting
- ✅ `GetError_Returns_NoError_By_Default` - Verifies default error code

### Startup Status Tests (3 tests)
- ✅ `GetStartupStatus_Returns_InternalError_Before_Init` - Tests uninitialized state
- ✅ `GetStartupStatus_Returns_Valid_After_Init` - Verifies status after initialization
- ✅ `GetStartupStatus_NotReleased_When_Release_Is_False` - Tests release condition handling

### Release Configuration Tests (2 tests)
- ✅ `Init_With_ExternalRelease_Configures_DefaultAutoStartup` - Tests external release configuration
- ✅ `Init_Without_ExternalRelease_Uses_AlwaysReleased` - Verifies null-object pattern for release

### StartUpTime Configuration Tests (2 tests)
- ✅ `StartUpTime_Default_Is_5_Seconds` - Verifies default startup time
- ✅ `StartUpTime_Can_Be_Changed` - Tests custom startup time configuration

### ResetActive Tests (1 test)
- ✅ `ResetActive_Returns_False_By_Default` - Tests default reset behavior

### Integration Tests (3 tests)
- ✅ `Full_Lifecycle_Without_Errors` - Tests complete initialization and execution cycle
- ✅ `Error_State_Prevents_UserCode_Execution` - Verifies error handling in full cycle
- ✅ `Mode_Change_From_Manual_To_Automatic` - Tests operating mode transitions

## Mock Classes

### MockEquipmentBase
Concrete implementation of the abstract `EquipmentBase` class for testing:
- Tracks calls to `RunCyclicUserCode` and `InitUser`
- Provides call counters for verification
- Includes `ResetTestFlags()` helper method

### MockAutoStartup
Mock implementation of `ItfAutoStartup`:
- Configurable `startupStatus` property
- Returns configured status via `Status()` method

### StartUpStatusAssert
Custom assertion function for `StartUpStatus` enum comparisons:
- Provides clear error messages showing expected vs actual values
- Follows the same pattern as `SupervisionAssert`

## Usage Example

```iecst
VAR
    equipment : MockEquipmentBase;
    mockMode : MockOperatingMode;
END_VAR

// Setup
equipment.Mode := mockMode;
mockMode.mode := OperatingModes#Automatic;

// Execute
equipment.RunCyclic();

// Verify
Equal(expected := TRUE, actual := equipment.InitUserCalled);
Equal(expected := FALSE, actual := equipment.HasError());
```

## Build Status

✅ All test files compile successfully without errors
✅ Integration with existing test infrastructure complete
✅ Compatible with AxUnit test framework

## Notes

- Tests use stateless pattern for test fixtures (equipmentStateless, mockModeStateless)
- Custom enum assertions required due to AxUnit limitations with enum types
- Tests cover both positive and negative scenarios
- Error handling and edge cases are thoroughly tested
