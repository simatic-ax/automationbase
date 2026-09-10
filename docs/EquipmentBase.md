# EquipmentBase

## Overview

`EquipmentBase` is an abstract base class that provides a structured foundation for all equipment in SIMATIC AX automation applications. It implements the `IEquipmentBase` interface and manages the complete equipment lifecycle including initialization, cyclic execution, error handling, and automatic startup sequences.

## Purpose

The `EquipmentBase` class serves as the foundation for creating standardized equipment implementations with:
- Automatic initialization on first cycle
- Built-in error state management
- Configurable automatic startup with safety timers
- Operating mode integration
- External release control for safety interlocks

## Class Declaration

```iec-st
CLASS ABSTRACT EquipmentBase IMPLEMENTS IEquipmentBase
```

## Public Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `StartUpTime` | TIME | T#5s | Duration of the startup warning phase before equipment is fully started |
| `Mode` | IOperatingMode | - | **Mandatory**: Operating mode provider. If not set, equipment will report `ConfigError` |
| `ExternalRelease` | IRelease | NULL | Optional: External release provider. If NULL, the internal `AlwaysReleasedRelease` implementation keeps the equipment released by default |
| `ExternalAutoStartup` | IAutoStartup | NULL | Optional: Custom auto-startup implementation. If NULL, uses internal default |

## Public Methods

### RunCyclic()
Main cyclic method that must be called in every PLC cycle. Handles:
- Automatic initialization on first call
- Error state checking
- Cyclic user code execution

```iec-st
METHOD PUBLIC RunCyclic
```

**Usage:**
```iec-st
myEquipment.RunCyclic();  // Call every cycle
```

### HasError() : BOOL
Returns TRUE if any error is active.

```iec-st
METHOD PUBLIC HasError : BOOL
```

**Returns:** TRUE if error state is not `NoError`

### GetError() : WORD
Returns the current error state code.

```iec-st
METHOD PUBLIC GetError : WORD
```

**Returns:** Current error code (see `ErrorState` type)

### SetError(errorState : WORD)
Sets an error state without error text. Clears any existing error message.

```iec-st
METHOD PUBLIC SetError
    VAR_INPUT
        errorState : WORD;
    END_VAR
END_METHOD
```

**Parameters:**
- `errorState`: Error code to set (e.g., `ErrorState#ConfigError`)

### SetError(errorState : WORD, errorText : STRING[30])
Sets an error state with a descriptive error message.

```iec-st
METHOD PUBLIC SetError
    VAR_INPUT
        errorState : WORD;
        errorText : STRING[30];
    END_VAR
END_METHOD
```

**Parameters:**
- `errorState`: Error code to set (e.g., `ErrorState#OtherError`)
- `errorText`: Descriptive error message (max 30 characters)

**Example:**
```iec-st
THIS.SetError(errorState := ErrorState#OtherError,
              errorText := 'Motor overload detected');
```

### GetErrorText() : STRING[30]
Returns the last error message.

```iec-st
METHOD PUBLIC GetErrorText : STRING[30]
```

**Returns:** Last error message text (empty string if no error or no text was set)

### GetStartupStatus() : StartUpStatus
Returns the current startup status of the equipment.

```iec-st
METHOD PUBLIC GetStartupStatus : StartUpStatus
```

**Returns:** Current startup status (NotReleased, AutoStartingUp, AutoStartedUp, InternalError)

### ResetFault()
Resets the fault state and clears the error message.

```iec-st
METHOD PUBLIC ResetFault
```

**Usage:**
```iec-st
IF resetButton THEN
    equipment.ResetFault();
END_IF;
```

## Protected Abstract Methods

These methods **must** be implemented in derived classes:

### InitUser()
Called once during initialization. Implement equipment-specific initialization here.

```iec-st
METHOD PROTECTED ABSTRACT InitUser
```

**Example:**
```iec-st
METHOD PROTECTED OVERRIDE InitUser
    Speed := 0.0;
    Running := FALSE;
    logger.LogInfo('Equipment initialized');
END_METHOD
```

### RunCyclicUserCode()
Called every cycle after initialization. Implement equipment-specific cyclic logic here.

```iec-st
METHOD PROTECTED ABSTRACT RunCyclicUserCode
```

**Example:**
```iec-st
METHOD PROTECTED OVERRIDE RunCyclicUserCode
    IF (THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp) THEN
        // The equipment may only move after startup is complete.
        Running := TRUE;
        IF (Mode.GetOperatingMode() = OperatingModes#Automatic) THEN
            Speed := 100.0;
        ELSE
            Speed := 0.0;
        END_IF;
    ELSE
        Running := FALSE;
        Speed := 0.0;
    END_IF;
END_METHOD
```

## Usage Example

### Creating Custom Equipment

```iec-st
USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.AutomationBase.Tests.ApplicationExample_01

CLASS MyConveyor EXTENDS EquipmentBase
    VAR PUBLIC
        Speed : LREAL;
        Running : BOOL;
    END_VAR
    
    METHOD PROTECTED OVERRIDE InitUser
        // Initialize outputs to a defined idle state.
        Speed := 0.0;
        Running := FALSE;
    END_METHOD
    
    METHOD PROTECTED OVERRIDE RunCyclicUserCode
        IF (THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp) THEN
            // Mirror the ApplicationExample_01 behavior.
            Running := TRUE;

            IF (Mode.GetOperatingMode() = OperatingModes#Automatic) THEN
                Speed := 100.0;
            ELSE
                Speed := 0.0;
            END_IF;
        ELSE
            Running := FALSE;
            Speed := 0.0;
        END_IF;
    END_METHOD

    METHOD PROTECTED OVERRIDE ResetFaultUser : BOOL
        ResetFaultUser := TRUE;
    END_METHOD
END_CLASS

END_NAMESPACE
```

### Using Equipment in Application

```iec-st
USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.AutomationBase.Tests.ApplicationExample_01

PROGRAM ConveyorDemo
    VAR
        conveyor : MyConveyor;
        modeManager : OperatingModeManager;
        releaseByBool : BoolRelease;
    END_VAR
    
    // Configure the equipment before the first cycle.
    conveyor.Mode := modeManager;
    conveyor.ExternalRelease := releaseByBool;
    conveyor.StartUpTime := T#0s;

    // This matches the tested startup path from ApplicationExample_01.
    modeManager.SetOperatingMode(mode := OperatingModes#Automatic);
    releaseByBool.ReleaseSignal := TRUE;
    
    conveyor.RunCyclic();

    // Withdraw the release and let the next cycle stop the conveyor.
    releaseByBool.ReleaseSignal := FALSE;
    conveyor.RunCyclic();
END_PROGRAM

END_NAMESPACE
```

## Lifecycle

1. **First RunCyclic() call**: Automatic initialization
   - Validates `Mode` property (mandatory)
   - Configures auto-startup (external or default)
   - Calls `InitUser()` for custom initialization

2. **Subsequent RunCyclic() calls**:
   - Checks for configuration errors
   - Runs default auto-startup if configured
   - Calls `RunCyclicUserCode()` for equipment logic

## Error Handling

### Configuration Error
If `Mode` is not assigned, equipment sets `ConfigError` and stops execution:

```iec-st
IF conveyor.HasError() THEN
    IF conveyor.GetError() = ErrorState#ConfigError THEN
        // Mode property not assigned
    END_IF;
END_IF;
```

### Custom Errors
Set custom errors with descriptive messages from derived classes:

```iec-st
METHOD PROTECTED OVERRIDE RunCyclicUserCode
    IF (temperatureTooHigh) THEN
        THIS.SetError(errorState := ErrorState#OtherError,
                      errorText := 'Temperature > 80°C');
    END_IF;
END_METHOD
```

### Error Reset
Reset errors when conditions are resolved:

```iec-st
METHOD PROTECTED OVERRIDE RunCyclicUserCode
    IF (resetButton AND THIS.HasError()) THEN
        THIS.ResetFault();
    END_IF;
END_METHOD
```

### Error Information Retrieval
Get detailed error information:

```iec-st
IF equipment.HasError() THEN
    errorCode := equipment.GetError();
    errorMessage := equipment.GetErrorText();
    
    CASE errorCode OF
        ErrorState#ConfigError:
            // Handle configuration error
            ;
        ErrorState#OtherError:
            // Log error message for diagnostics
            logger.LogError(errorMessage);
    END_CASE;
END_IF;
```

## Best Practices

1. **Always assign Mode**: The `Mode` property is mandatory
   ```iec-st
   equipment.Mode := modeManager;  // Required!
   ```

2. **Use ExternalRelease for safety**: Integrate safety systems
   ```iec-st
   equipment.ExternalRelease := safetyRelease;
   ```

3. **Override protected methods only**: Never override `Init()` or `RunCyclic()` directly
   ```iec-st
   // ✓ Correct
   METHOD PROTECTED OVERRIDE InitUser
   
   // ✗ Wrong
   METHOD PUBLIC OVERRIDE Init
   ```

4. **Check startup status**: Before activating equipment
   ```iec-st
   IF (THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp) THEN
       // Safe to activate
   END_IF;
   ```

5. **Set appropriate startup times**: Based on safety requirements
   ```iec-st
   equipment.StartUpTime := T#10s;  // 10 second warning
   ```

## See Also

- [Release Management](Release.md) - External release control
- [Startup Warning](StartupWarning.md) - Automatic startup behavior
- [Operating Modes](OperatingModes.md) - Operating mode management
- [Error States](ErrorStates.md) - Error state definitions
