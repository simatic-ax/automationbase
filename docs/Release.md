# Release Management

## Overview

The Release interface (`ItfRelease`) provides a mechanism to control when equipment is allowed to start or operate. This is essential for implementing safety interlocks, upstream dependencies, and conditional equipment activation.

## Interface Definition

```iec-st
INTERFACE ItfRelease
    METHOD IsReleased : BOOL
    END_METHOD
END_INTERFACE
```

## Purpose

Release management allows you to:
- Implement safety interlocks (emergency stops, safety gates)
- Create dependencies between equipment (upstream must be running)
- Control equipment activation based on process conditions
- Integrate external permission systems

## Method

### IsReleased() : BOOL

Returns TRUE when the equipment is released and allowed to operate.

**Returns:**
- `TRUE`: Equipment is released and may start/operate
- `FALSE`: Equipment is not released and must remain stopped

If the release is withdrawn during operation, the equipment returns to `StartUpStatus#NotReleased` on the next cycle and user code can react by stopping outputs or motion.

## Built-In Default Implementation

The library contains an internal null-object implementation named `AlwaysReleasedRelease`:

```iec-st
CLASS INTERNAL AlwaysReleasedRelease IMPLEMENTS IRelease
    METHOD PUBLIC IsReleased : BOOL
        IsReleased := TRUE;
    END_METHOD
END_CLASS
```

This implementation is used internally when `ExternalRelease` is `NULL`. In that case, the equipment behaves as permanently released until you assign a custom `IRelease` implementation.

## Usage Examples

### Simple Boolean Release

Use this when the release condition is already available as a plain `BOOL`.

```iec-st
USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.AutomationBase.Tests.ApplicationExample_01

PROGRAM ConveyorReleaseDemo
    VAR
        conveyor : MyConveyor;
        modeProvider : OperatingModeManager;
        releaseByBool : BoolRelease;
    END_VAR

    // Configure the same dependencies used in ApplicationExample_01.
    conveyor.Mode := modeProvider;
    conveyor.ExternalRelease := releaseByBool;
    conveyor.StartUpTime := T#0s;

    // Automatic mode and a TRUE release produce AutoStartedUp.
    modeProvider.SetOperatingMode(mode := OperatingModes#Automatic);

    releaseByBool.ReleaseSignal := TRUE;
    conveyor.RunCyclic();

    // A withdrawn release moves the equipment back to NotReleased.
    releaseByBool.ReleaseSignal := FALSE;
    conveyor.RunCyclic();
END_PROGRAM

END_NAMESPACE
```

This pattern is useful when the equipment may already be running and must stop immediately once the release condition is no longer fulfilled.

### Binary Signal Release

Use this when the release comes from an `IBinSignal`, for example from IO or an HMI abstraction.

```iec-st
USING Simatic.Ax.AutomationBase;

VAR
    conveyor : MyConveyor;
    releaseBySignal : BinSignalRelease;
END_VAR

releaseBySignal.ReleaseSignal := releaseInput;
conveyor.ExternalRelease := releaseBySignal;
```

### Safety Release Implementation

```iec-st
USING Simatic.Ax.AutomationBase;

CLASS SafetyRelease IMPLEMENTS ItfRelease
    VAR PUBLIC
        EmergencyStop : BOOL;
        SafetyGateOpen : BOOL;
        MaintenanceMode : BOOL;
    END_VAR
    
    METHOD PUBLIC IsReleased : BOOL
        // Equipment is released only when all safety conditions are met
        IsReleased := NOT EmergencyStop 
                      AND NOT SafetyGateOpen 
                      AND NOT MaintenanceMode;
    END_METHOD
END_CLASS
```

### Upstream Dependency Release

```iec-st
USING Simatic.Ax.AutomationBase;

CLASS UpstreamRelease IMPLEMENTS ItfRelease
    VAR PUBLIC
        UpstreamEquipment : ItfEquipmentBase;
        RequireStartedUp : BOOL := TRUE;
    END_VAR
    
    METHOD PUBLIC IsReleased : BOOL
        IF (UpstreamEquipment = NULL) THEN
            IsReleased := FALSE;
            RETURN;
        END_IF;
        
        IF RequireStartedUp THEN
            // Only release if upstream is fully started
            IsReleased := (UpstreamEquipment.GetStartupStatus() = StartUpStatus#AutoStartedUp)
                          AND NOT UpstreamEquipment.HasError();
        ELSE
            // Release if upstream has no errors
            IsReleased := NOT UpstreamEquipment.HasError();
        END_IF;
    END_METHOD
END_CLASS
```

### Combined Release Conditions

```iec-st
USING Simatic.Ax.AutomationBase;

CLASS CombinedRelease IMPLEMENTS ItfRelease
    VAR PUBLIC
        SafetyRelease : ItfRelease;
        ProcessRelease : ItfRelease;
        ManualOverride : BOOL;
    END_VAR
    
    METHOD PUBLIC IsReleased : BOOL
        // Manual override bypasses all checks
        IF ManualOverride THEN
            IsReleased := TRUE;
            RETURN;
        END_IF;
        
        // Both safety and process must release
        IsReleased := SafetyRelease.IsReleased() 
                      AND ProcessRelease.IsReleased();
    END_METHOD
END_CLASS
```

### Time-Based Release

```iec-st
USING Simatic.Ax.AutomationBase;
USING System.Timer;

CLASS TimeBasedRelease IMPLEMENTS ItfRelease
    VAR PUBLIC
        StartTime : TIME_OF_DAY := TOD#08:00:00;
        EndTime : TIME_OF_DAY := TOD#17:00:00;
        CurrentTime : TIME_OF_DAY;
    END_VAR
    
    METHOD PUBLIC IsReleased : BOOL
        // Release only during specified time window
        IF StartTime < EndTime THEN
            IsReleased := (CurrentTime >= StartTime) AND (CurrentTime <= EndTime);
        ELSE
            // Handle overnight window (e.g., 22:00 to 06:00)
            IsReleased := (CurrentTime >= StartTime) OR (CurrentTime <= EndTime);
        END_IF;
    END_METHOD
END_CLASS
```

## Integration with Equipment

### Basic Integration

```iec-st
PROGRAM MyApplication
    VAR
        conveyor : MyConveyor;
        safetyRelease : SafetyRelease;
    END_VAR
    
    // Configure release
    conveyor.ExternalRelease := safetyRelease;
    
    // Cyclic execution
    conveyor.RunCyclic();
```

### Optional Release (Null-Object Pattern)

If `ExternalRelease` is not assigned (NULL), the equipment uses the internal `AlwaysReleasedRelease` implementation:

```iec-st
// No external release assigned
conveyor.ExternalRelease := NULL;  // Equipment is always released
conveyor.RunCyclic();
```

## Provided Implementations

The library currently provides these reusable `IRelease` implementations:

- `AlwaysReleasedRelease`: Internal null-object implementation that always returns `TRUE`
- `BoolRelease`: Returns the value of a public `BOOL` property
- `BinSignalRelease`: Returns the current state of an assigned `IBinSignal`; if no signal is assigned, it returns `FALSE`

## Behavior in Automatic Startup

The release state affects automatic startup:

1. **Not Released** (`IsReleased() = FALSE`):
   - Startup status: `StartUpStatus#NotReleased`
   - Startup timer is not running
   - Equipment remains stopped

2. **Released** (`IsReleased() = TRUE`):
   - If in Automatic mode and no errors: Startup begins
   - Startup status: `StartUpStatus#AutoStartingUp`
   - After startup time elapses: `StartUpStatus#AutoStartedUp`

3. **Release Lost During Startup**:
   - Startup timer resets
   - Returns to `StartUpStatus#NotReleased`
   - Must be released again to restart

## Best Practices

1. **Keep IsReleased() lightweight**: Called every PLC cycle
   ```iec-st
   // ✓ Good - simple boolean logic
   IsReleased := NOT emergencyStop AND NOT gateOpen;
   
   // ✗ Avoid - complex calculations
   IsReleased := CalculateComplexCondition();
   ```

2. **Handle NULL checks**: If using references
   ```iec-st
   IF (UpstreamEquipment = NULL) THEN
       IsReleased := FALSE;
       RETURN;
   END_IF;
   ```

3. **Use for safety-critical conditions**: Don't bypass safety
   ```iec-st
   // ✓ Correct - safety always checked
   IsReleased := NOT EmergencyStop AND processCondition;
   
   // ✗ Wrong - safety can be bypassed
   IsReleased := manualOverride OR (NOT EmergencyStop);
   ```

4. **Document release conditions**: Make logic clear
   ```iec-st
   /// <summary>
   /// Equipment is released when:
   /// - Emergency stop is not active
   /// - Safety gate is closed
   /// - Upstream conveyor is running
   /// </summary>
   METHOD PUBLIC IsReleased : BOOL
   ```

5. **Test release logic thoroughly**: Verify all conditions
   ```iec-st
   // Test all combinations of inputs
   ```

## Common Patterns

### Always Released (Default)

```iec-st
CLASS AlwaysReleased IMPLEMENTS ItfRelease
    METHOD PUBLIC IsReleased : BOOL
        IsReleased := TRUE;
    END_METHOD
END_CLASS
```

### Never Released (Maintenance)

```iec-st
CLASS NeverReleased IMPLEMENTS ItfRelease
    METHOD PUBLIC IsReleased : BOOL
        IsReleased := FALSE;
    END_METHOD
END_CLASS
```

### Conditional Release

```iec-st
CLASS ConditionalRelease IMPLEMENTS ItfRelease
    VAR PUBLIC
        Condition : BOOL;
    END_VAR
    
    METHOD PUBLIC IsReleased : BOOL
        IsReleased := Condition;
    END_METHOD
END_CLASS
```

## See Also

- [EquipmentBase](EquipmentBase.md) - Equipment base class
- [Startup Warning](StartupWarning.md) - Automatic startup behavior
- [Operating Modes](OperatingModes.md) - Operating mode management
