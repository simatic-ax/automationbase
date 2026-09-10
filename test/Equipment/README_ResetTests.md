# Reset Command Tests

## Overview

This directory contains comprehensive unit and integration tests for the Reset Command system.

## Test Files

### ResetCommandManagerTest.st
Unit tests for the `ResetCommandManager` class in isolation.

**Test Coverage:**
- Initial state verification
- Reset trigger and edge detection
- Registration counting
- Acknowledgment counting
- Reset cycle phases (3-phase cycle)
- Multiple reset cycles
- Counter reset between cycles

**Key Tests:**
- `Test_InitialState_IsNotPending` - Verifies manager starts in idle state
- `Test_TriggerReset_EdgeDetection_OnlyTriggersOnce` - Edge detection works correctly
- `Test_RegistrationCount_CountsEquipmentChecks` - Counts all equipment that check for reset
- `Test_AcknowledgmentCount_CountsAcknowledgments` - Counts only equipment with errors
- `Test_ResetCycle_CompletesAfterThreeCycles` - Verifies 3-phase cycle timing
- `Test_MultipleResets_CountersResetCorrectly` - Counters reset between cycles

### ResetCommandIntegrationTest.st
Integration tests with multiple equipment instances using the reset manager.

**Test Coverage:**
- Single equipment reset
- Multiple equipment reset (all with errors)
- Mixed scenario (some with errors, some without)
- No equipment with errors
- Complete reset cycle timing
- Multiple reset cycles
- Equipment without ResetCommand
- Manual reset functionality
- Error text clearing
- Large number of equipment (8 equipment)

**Key Tests:**
- `Test_SingleEquipmentWithError_ResetsSuccessfully` - Basic reset functionality
- `Test_MultipleEquipmentWithErrors_AllReset` - All equipment reset when all have errors
- `Test_MixedEquipment_OnlyErrorsReset` - Only equipment with errors acknowledge
- `Test_NoEquipmentWithErrors_NoAcknowledgments` - No acknowledgments when no errors
- `Test_ResetCycle_CompletesCorrectly` - Full cycle with equipment
- `Test_MultipleResetCycles_WorkCorrectly` - Multiple cycles work independently
- `Test_EquipmentWithoutResetCommand_NotAffected` - Equipment without ResetCommand not affected
- `Test_ManualResetFault_WorksIndependently` - Manual reset still works
- `Test_LargeNumberOfEquipment_AllResetCorrectly` - Scales to many equipment

## Mock Equipment

### MockEquipmentForReset
Test double that extends `EquipmentBase` for testing purposes.

**Features:**
- `SimulateError` - Trigger to create error condition
- `ResetWasCalled` - Flag indicating reset was executed
- `ResetCallCount` - Counter for number of resets
- `CustomResetValue` - Test value to verify custom reset logic

**Custom Reset Logic:**
Overrides `ResetFaultUser()` to set test values, allowing verification that custom reset logic executes correctly.

## Running Tests

### Using APAX CLI

```bash
# Run all tests
apax test

# Run only reset tests
apax test --filter "ResetCommand"

# Run with coverage (LLVM engine)
apax test --coverage
```

### Using VS Code

1. Open Test Explorer
2. Navigate to `test/Equipment/`
3. Run individual tests or entire test fixtures

## Test Scenarios

### Scenario 1: Single Equipment Reset
```
Equipment1: Has error
Action: Trigger reset
Expected: Equipment1 resets, error cleared
```

### Scenario 2: Multiple Equipment, All With Errors
```
Equipment1: Has error
Equipment2: Has error
Equipment3: Has error
Action: Trigger reset
Expected: All equipment reset, all errors cleared
Registered: 3, Acknowledged: 3
```

### Scenario 3: Mixed Equipment
```
Equipment1: Has error
Equipment2: No error
Equipment3: Has error
Action: Trigger reset
Expected: Only Equipment1 and Equipment3 reset
Registered: 3, Acknowledged: 2
```

### Scenario 4: No Errors
```
Equipment1: No error
Equipment2: No error
Equipment3: No error
Action: Trigger reset
Expected: No resets executed
Registered: 3, Acknowledged: 0
```

### Scenario 5: Reset Cycle Timing
```
Cycle 1: Trigger, register, acknowledge → Pending
Cycle 2: Acknowledgment phase → Pending
Cycle 3: Completion phase → Pending
Cycle 4: Complete → Not pending
```

### Scenario 6: Multiple Reset Cycles
```
Cycle 1-4: First reset (Equipment1 has error)
Cycle 5-8: Second reset (Equipment1 and Equipment2 have errors)
Expected: Both cycles work independently
```

### Scenario 7: Large Scale (8 Equipment)
```
Equipment1,3,5,7: Have errors
Equipment2,4,6,8: No errors
Action: Trigger reset
Expected: Only odd-numbered equipment reset
Registered: 8, Acknowledged: 4
```

## Verification Points

### Manager State
- ✅ Initial state is not pending
- ✅ Trigger sets pending flag
- ✅ Edge detection prevents continuous triggering
- ✅ Cycle completes after 3 phases
- ✅ Counters reset between cycles

### Equipment Behavior
- ✅ Only equipment with errors call `ResetFaultUser()`
- ✅ All equipment register (call `GetResetCommand()`)
- ✅ Custom reset logic executes correctly
- ✅ Error state and text cleared
- ✅ Equipment without ResetCommand not affected

### Integration
- ✅ Multiple equipment share one manager
- ✅ Registration count = all equipment
- ✅ Acknowledgment count = equipment with errors
- ✅ Reset completes correctly with timing
- ✅ Multiple cycles work independently
- ✅ Scales to many equipment

## Best Practices for Testing

1. **Always initialize equipment** - Call `RunCyclic()` once before testing
2. **Complete full cycles** - Run manager `RunCyclic()` 3 times to complete reset
3. **Verify both flags and behavior** - Check both state flags and actual reset execution
4. **Test edge cases** - No errors, all errors, mixed scenarios
5. **Test timing** - Verify 3-phase cycle works correctly
6. **Test scale** - Verify works with many equipment

## Common Test Patterns

### Pattern 1: Setup Equipment with Error
```iec-st
equipment.SimulateError := TRUE;
equipment.RunCyclic();
Assert.Equal(TRUE, equipment.HasError());
```

### Pattern 2: Execute Complete Reset Cycle
```iec-st
resetManager.TriggerReset();
equipment1.RunCyclic();
equipment2.RunCyclic();
equipment3.RunCyclic();
resetManager.RunCyclic(); // Phase 1->2
resetManager.RunCyclic(); // Phase 2->3
resetManager.RunCyclic(); // Phase 3->0
```

### Pattern 3: Verify Reset Execution
```iec-st
Assert.Equal(FALSE, equipment.HasError());
Assert.Equal(TRUE, equipment.ResetWasCalled);
Assert.Equal(42, equipment.CustomResetValue);
```

### Pattern 4: Verify Counts
```iec-st
Assert.Equal(3, resetManager.GetRegisteredEquipmentCount());
Assert.Equal(2, resetManager.GetAcknowledgmentCount());
```

## Troubleshooting Tests

### Test fails: "Reset not executed"
- Ensure `resetManager.RunCyclic()` is called after equipment
- Verify equipment has `ResetCommand` assigned
- Check that equipment actually has an error

### Test fails: "Wrong acknowledgment count"
- Verify only equipment with errors should acknowledge
- Check that all equipment call `RunCyclic()` before manager

### Test fails: "Reset stays pending"
- Ensure manager `RunCyclic()` is called 3 times
- Verify cycle phases progress correctly

## See Also

- [EquipmentBase Tests](EquipmentBaseTest.st) - Base equipment functionality tests
- [Reset Command Documentation](../../docs/ResetCommand.md) - Full documentation
- [Reset Command Example](../../examples/ResetCommandExample.st) - Usage example
