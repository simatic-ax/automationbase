# Reset Command Management

## Overview

The Reset Command system provides centralized reset control for equipment instances, similar to how Operating Modes work. This allows a single reset trigger (e.g., HMI button) to automatically reset all connected equipment that has errors.

## Architecture

The system consists of four components:

1. **`IResetCommand`** - Interface for reset command providers
2. **`ResetCommandManager`** - Central manager with automatic edge detection
3. **`EquipmentBase.ResetCommand`** - Optional property to connect equipment to reset manager
4. **`ResetFaultUser()`** - Protected method for custom reset logic in derived classes

## Key Concepts

### Centralized Control
- One `ResetCommandManager` instance can control multiple equipment
- Similar pattern to `OperatingModeManager` for consistency
- Equipment automatically resets when manager triggers reset command

### Simple One-Cycle Reset
- Reset command is active for **exactly one cycle**
- Reset is triggered on rising edge of `ResetSignal`
- No manual acknowledgment needed - reset clears automatically after one cycle
- Equipment reports errors via `ReportError()` every cycle while error is active

### Automatic Edge Detection
- Manager automatically detects rising edge via `ResetSignal.QRis()`
- Reset command is set at start of `RunCyclic()` only on rising edge
- Reset command is cleared at start of next `RunCyclic()` call
- Ensures cycle-consistent behavior

### Optional Integration
- `ResetCommand` property is optional (can be NULL)
- Equipment without reset command can still use manual `ResetFault()` method
- Flexible integration for different use cases

### Custom Reset Logic
- Override `ResetFaultUser()` in derived classes for equipment-specific reset
- Base implementation clears error state and text
- Each equipment can have its own reset behavior while using shared manager

## Usage

### Basic Setup

```iec-st
USING Simatic.Ax.AutomationBase;
USING Simatic.Ax.IO.Input;

PROGRAM MyApplication
    VAR
        // Equipment instances
        conveyor1 : MyConveyor;
        conveyor2 : MyConveyor;
        robot : MyRobot;
        
        // Central reset manager
        resetManager : ResetCommandManager;
        
        // HMI reset button signal
        hmiResetButton : BinSignal;
    END_VAR
    
    // Configuration
    conveyor1.ResetCommand := resetManager;
    conveyor2.ResetCommand := resetManager;
    robot.ResetCommand := resetManager;
    
    // Connect reset signal to manager
    resetManager.ResetSignal := hmiResetButton;
    
    // Read HMI button state
    hmiResetButton.ReadCyclic(signal := (* your HMI button input *), valid := TRUE);
    
    // Cyclic execution - automatic reset when triggered
    conveyor1.RunCyclic();
    conveyor2.RunCyclic();
    robot.RunCyclic();
    
    // IMPORTANT: Manager must run after all equipment
    // RunCyclic automatically detects reset signal edge
    resetManager.RunCyclic();
END_PROGRAM
```

### Selective Reset

You can create multiple reset managers for different equipment groups:

```iec-st
VAR
    // Equipment
    conveyor1 : MyConveyor;
    conveyor2 : MyConveyor;
    robot1 : MyRobot;
    robot2 : MyRobot;
    
    // Separate reset managers
    conveyorResetManager : ResetCommandManager;
    robotResetManager : ResetCommandManager;
    
    // Separate reset button signals
    conveyorResetSignal : BinSignal;
    robotResetSignal : BinSignal;
END_VAR

// Configure conveyor group
conveyor1.ResetCommand := conveyorResetManager;
conveyor2.ResetCommand := conveyorResetManager;
conveyorResetManager.ResetSignal := conveyorResetSignal;

// Configure robot group
robot1.ResetCommand := robotResetManager;
robot2.ResetCommand := robotResetManager;
robotResetManager.ResetSignal := robotResetSignal;

// Read reset button signals
conveyorResetSignal.ReadCyclic(signal := (* conveyor reset button *), valid := TRUE);
robotResetSignal.ReadCyclic(signal := (* robot reset button *), valid := TRUE);

// Execute equipment
conveyor1.RunCyclic();
conveyor2.RunCyclic();
robot1.RunCyclic();
robot2.RunCyclic();

// Run managers after their equipment (automatic edge detection)
conveyorResetManager.RunCyclic();
robotResetManager.RunCyclic();
```

### Mixed Reset Strategy

Combine automatic and manual reset:

```iec-st
VAR
    criticalEquipment : MyCriticalEquipment;
    standardEquipment : MyStandardEquipment;
    
    resetManager : ResetCommandManager;
    globalResetSignal : BinSignal;
    
    manualCriticalReset : BOOL;
END_VAR

// Critical equipment: manual reset only (no ResetCommand assigned)
// criticalEquipment.ResetCommand := NULL;  // Default

// Standard equipment: automatic reset
standardEquipment.ResetCommand := resetManager;
resetManager.ResetSignal := globalResetSignal;

// Read global reset button
globalResetSignal.ReadCyclic(signal := (* global reset button *), valid := TRUE);

// Manual reset for critical equipment (requires explicit action)
IF (manualCriticalReset AND criticalEquipment.HasError()) THEN
    criticalEquipment.ResetFault();
END_IF;

standardEquipment.RunCyclic();
criticalEquipment.RunCyclic();

// Run manager after equipment (automatic edge detection)
resetManager.RunCyclic();
```

## API Reference

### IResetCommand Interface

```iec-st
INTERFACE IResetCommand
    /// Returns TRUE when a reset command is active
    METHOD GetResetCommand : BOOL
    END_METHOD
    
    /// Equipment calls this to report it has an active error
    METHOD ReportError
    END_METHOD
    
    /// Returns TRUE if any equipment has reported an active error
    METHOD AnyErrorActive : BOOL
    END_METHOD
    
    /// Returns TRUE if reset command is currently active
    METHOD IsResetActive : BOOL
    END_METHOD
END_INTERFACE
```

### ResetCommandManager Class

#### Properties

**`ResetSignal : IBinSignal`**
- Reset signal input (connect to HMI button or other signal source)
- Reset is triggered on rising edge via `QRis()`
- Automatic edge detection in `RunCyclic()`

#### Methods

**`RunCyclic()`**
- **IMPORTANT**: Must be called every cycle after all equipment
- Automatically detects reset signal edge via `ResetSignal.QRis()`
- Clears reset command at start of cycle
- Sets reset command only on rising edge
- Clears error flag on reset

**`GetResetCommand() : BOOL`**
- Returns TRUE when reset command is active (for exactly one cycle)
- Called automatically by EquipmentBase
- Equipment checks this to determine if reset should be attempted

**`ReportError()`**
- Equipment calls this to report it has an active error
- Must be called every cycle while equipment has an error
- Called automatically by EquipmentBase when `HasError()` is TRUE
- Sets internal error flag

**`AnyErrorActive() : BOOL`**
- Returns TRUE if any equipment has reported an error in current cycle
- Useful for HMI feedback
- Indicates at least one equipment has an active error

**`IsResetActive() : BOOL`**
- Returns TRUE if reset command is currently active
- Same as `GetResetCommand()`
- Useful for HMI feedback

### EquipmentBase

#### Properties

**`ResetCommand : IResetCommand`**
- Optional property (can be NULL)
- Connects equipment to reset command provider
- When assigned, equipment automatically resets on command

#### Methods

**`ResetFault()`** (PUBLIC)
- Manually resets the fault state
- Calls `ResetFaultUser()` internally
- Can be called directly or triggered via ResetCommand

**`ResetFaultUser()`** (PROTECTED)
- Override this in derived classes for custom reset logic
- Default implementation clears `_errorState` and `_errorText`
- Always call `SUPER^.ResetFaultUser()` to ensure base reset logic executes

## How It Works

### Reset Cycle Flow

The ResetCommandManager uses a simple one-cycle reset:

**Cycle N: Normal operation**
- Equipment with errors call `ReportError()` automatically
- `resetManager.AnyErrorActive()` returns TRUE
- Reset button not pressed

**Cycle N+1: Reset triggered (rising edge)**
- Reset button pressed: `resetSignal.ReadCyclic(signal := TRUE, valid := TRUE)`
- `resetManager.RunCyclic()` detects rising edge via `QRis()`
- Reset command activated for this cycle
- Error flag cleared
- Equipment call `GetResetCommand()` → returns TRUE
- Equipment with errors call `ResetFaultUser()` to clear errors

**Cycle N+2: Reset complete**
- `resetManager.RunCyclic()` clears reset command at start
- Equipment call `GetResetCommand()` → returns FALSE
- Back to normal operation

### Example Flow

```
Cycle 1: Normal operation with errors
  - equipment1.RunCyclic() → HasError() = TRUE, calls ReportError()
  - equipment2.RunCyclic() → HasError() = FALSE
  - equipment3.RunCyclic() → HasError() = TRUE, calls ReportError()
  - resetManager.RunCyclic() → AnyErrorActive() = TRUE
  - resetSignal.ReadCyclic(signal := FALSE, valid := TRUE)

Cycle 2: Reset button pressed (rising edge)
  - resetSignal.ReadCyclic(signal := TRUE, valid := TRUE)
  - resetManager.RunCyclic() → detects rising edge, activates reset, clears error flag
  - equipment1.RunCyclic() → GetResetCommand() = TRUE, calls ResetFaultUser()
  - equipment2.RunCyclic() → GetResetCommand() = TRUE, no error, no reset
  - equipment3.RunCyclic() → GetResetCommand() = TRUE, calls ResetFaultUser()

Cycle 3: Reset complete
  - resetSignal.ReadCyclic(signal := TRUE, valid := TRUE) // still held
  - resetManager.RunCyclic() → clears reset command (no rising edge)
  - equipment1.RunCyclic() → GetResetCommand() = FALSE
  - equipment2.RunCyclic() → GetResetCommand() = FALSE
  - equipment3.RunCyclic() → GetResetCommand() = FALSE
```

## Comparison with Operating Modes

| Aspect | Operating Modes | Reset Commands |
|--------|----------------|----------------|
| Purpose | Control equipment behavior | Reset equipment errors |
| Property | `Mode : IOperatingMode` | `ResetCommand : IResetCommand` |
| Manager | `OperatingModeManager` | `ResetCommandManager` |
| Mandatory | Yes (ConfigError if NULL) | No (optional) |
| Pattern | State-based | Event-based (edge detection) |
| Cyclic Call | Not required | Required (`RunCyclic()`) |
| Duration | Continuous state | One cycle only |

## Best Practices

### 1. Always Call resetManager.RunCyclic()
```iec-st
// ✓ Good: Manager runs after all equipment
equipment1.RunCyclic();
equipment2.RunCyclic();
equipment3.RunCyclic();
resetManager.RunCyclic();  // REQUIRED!

// ✗ Wrong: Missing RunCyclic()
equipment1.RunCyclic();
equipment2.RunCyclic();
// Reset will never work!
```

### 2. Use Central Manager for Groups
```iec-st
// ✓ Good: One manager for related equipment
lineResetManager : ResetCommandManager;
conveyor.ResetCommand := lineResetManager;
robot.ResetCommand := lineResetManager;
packaging.ResetCommand := lineResetManager;
```

### 3. Connect Reset Signal
```iec-st
// ✓ Good: Connect IBinSignal to manager
resetManager.ResetSignal := hmiResetButton;
hmiResetButton.ReadCyclic(signal := (* HMI button input *), valid := TRUE);
// RunCyclic() handles edge detection automatically
```

### 4. Override ResetFaultUser() for Custom Logic
```iec-st
// ✓ Good: Custom reset with base call
METHOD PROTECTED OVERRIDE ResetFaultUser
    SUPER^.ResetFaultUser();  // Clear error state
    
    // Custom reset logic
    Speed := 0.0;
    StateMachine := State#Idle;
    ResetCounter := ResetCounter + 1;
END_METHOD

// ✗ Wrong: Forgetting base call
METHOD PROTECTED OVERRIDE ResetFaultUser
    Speed := 0.0;  // Error state NOT cleared!
END_METHOD
```

### 5. Provide HMI Feedback
```iec-st
// ✓ Good: Show reset status on HMI
hmiResetActive := resetManager.IsResetActive();
hmiAnyError := resetManager.AnyErrorActive();
```

### 6. Consider Safety-Critical Equipment
```iec-st
// ✓ Good: Safety equipment requires manual reset
safetyEquipment.ResetCommand := NULL;  // No automatic reset
IF (operatorConfirmedSafe AND manualResetButton) THEN
    safetyEquipment.ResetFault();
END_IF;
```

### 7. Log Reset Events
```iec-st
// ✓ Good: Track reset operations
IF (resetManager.IsResetActive()) THEN
    logger.LogInfo('Central reset triggered');
END_IF;

// In custom ResetFaultUser():
METHOD PROTECTED OVERRIDE ResetFaultUser
    logger.LogInfo('Equipment reset executed');
    SUPER^.ResetFaultUser();
END_METHOD
```

## Example: Production Line

```iec-st
PROGRAM ProductionLine
    VAR
        // Line equipment
        infeedConveyor : Conveyor;
        processingStation : ProcessingStation;
        outfeedConveyor : Conveyor;
        
        // Central managers
        modeManager : OperatingModeManager;
        lineResetManager : ResetCommandManager;
        
        // HMI interface
        hmi_ResetButtonSignal : BinSignal;
        hmi_ResetActive : BOOL;
        hmi_LineHasErrors : BOOL;
    END_VAR
    
    // Configure all equipment with same reset manager
    infeedConveyor.Mode := modeManager;
    infeedConveyor.ResetCommand := lineResetManager;
    
    processingStation.Mode := modeManager;
    processingStation.ResetCommand := lineResetManager;
    
    outfeedConveyor.Mode := modeManager;
    outfeedConveyor.ResetCommand := lineResetManager;
    
    // Connect reset signal
    lineResetManager.ResetSignal := hmi_ResetButtonSignal;
    
    // Read HMI reset button
    hmi_ResetButtonSignal.ReadCyclic(signal := (* HMI reset button input *), valid := TRUE);
    
    // HMI feedback
    hmi_ResetActive := lineResetManager.IsResetActive();
    hmi_LineHasErrors := lineResetManager.AnyErrorActive();
    
    // Cyclic execution
    infeedConveyor.RunCyclic();
    processingStation.RunCyclic();
    outfeedConveyor.RunCyclic();
    
    // Manager runs after all equipment (automatic edge detection)
    lineResetManager.RunCyclic();
END_PROGRAM
```

## Custom Reset Logic Example

```iec-st
CLASS MyConveyor EXTENDS EquipmentBase
    VAR PUBLIC
        Speed : REAL;
        Running : BOOL;
        TotalResets : INT;
    END_VAR
    VAR PRIVATE
        _stateMachine : INT;
    END_VAR
    
    METHOD PROTECTED OVERRIDE InitUser
        Speed := 0.0;
        Running := FALSE;
        TotalResets := 0;
    END_METHOD
    
    METHOD PROTECTED OVERRIDE RunCyclicUserCode
        // Normal equipment logic
        IF (NOT THIS.HasError()) THEN
            Running := TRUE;
        ELSE
            Running := FALSE;
            Speed := 0.0;
        END_IF;
    END_METHOD
    
    /// Custom reset logic for conveyor
    METHOD PROTECTED OVERRIDE ResetFaultUser
        // IMPORTANT: Always call base implementation first
        SUPER^.ResetFaultUser();
        
        // Conveyor-specific reset actions
        Speed := 0.0;
        Running := FALSE;
        _stateMachine := 0;  // Reset state machine
        TotalResets := TotalResets + 1;
        
        // Could add more:
        // - Clear product counters
        // - Reset position tracking
        // - Log reset event with timestamp
        // - Send notification to SCADA
    END_METHOD
END_CLASS
```

## Troubleshooting

### Problem: Reset never triggers
**Cause**: Missing `resetManager.RunCyclic()` call
**Solution**: Always call `RunCyclic()` on the manager after all equipment

### Problem: Reset doesn't work
**Cause**: Manager `RunCyclic()` called before equipment
**Solution**: Ensure manager runs **after** all equipment

### Problem: Custom reset not working
**Cause**: Forgot to call `SUPER^.ResetFaultUser()` in override
**Solution**: Always call base implementation to clear error state

### Problem: Reset triggers every cycle
**Cause**: ResetSignal not properly connected or ReadCyclic not called
**Solution**: Ensure `ResetSignal.ReadCyclic()` is called every cycle with proper signal input

### Problem: Reset doesn't trigger at all
**Cause**: ResetSignal is NULL or not connected
**Solution**: Assign a valid IBinSignal to `resetManager.ResetSignal`

### Problem: No rising edge detected
**Cause**: Signal starts at TRUE or never goes LOW first
**Solution**: Ensure signal goes from FALSE to TRUE for rising edge detection

## See Also

- [EquipmentBase](EquipmentBase.md) - Base equipment class
- [Operating Modes](OperatingModes.md) - Operating mode management
- [Error States](ErrorStates.md) - Error state definitions
