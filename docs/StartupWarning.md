# Startup Warning and Automatic Startup

## Overview

The automatic startup system provides safe equipment activation in automatic mode with configurable warning times. This ensures operators have adequate warning before equipment starts automatically.

## StartUpStatus Enumeration

```iec-st
TYPE StartUpStatus : (
    InternalError,      // Configuration error in startup system
    NotReleased,        // Equipment not released or not in automatic mode
    AutoStartingUp,     // Startup warning active (timer running)
    AutoStartedUp       // Startup complete, equipment fully released
) := NotReleased;
```

## Status Descriptions

### InternalError
**Meaning:** Configuration error in the automatic startup system

**Causes:**
- `Mode` property not assigned (NULL)
- `Equipment` reference not set (internal configuration issue)

**Action:** Check equipment configuration, ensure `Mode` is assigned

### NotReleased
**Meaning:** Equipment is not released to start

**Causes:**
- Not in Automatic operating mode
- External release condition is FALSE (`ExternalRelease.IsReleased() = FALSE`)
- Equipment has an error (`HasError() = TRUE`)

**Action:** 
- Switch to Automatic mode
- Clear release conditions (safety gates, emergency stops, etc.)
- Clear equipment errors

### AutoStartingUp
**Meaning:** Startup warning phase is active

**Duration:** Configured by `StartUpTime` property (default: 5 seconds)

**Behavior:**
- Startup timer is running
- Equipment should indicate imminent startup (warning lights, sounds)
- Equipment should NOT yet be operating
- If release is lost, returns to `NotReleased`

**Action:** Operators should clear the area, prepare for equipment start

### AutoStartedUp
**Meaning:** Startup complete, equipment is fully released

**Behavior:**
- Startup timer has elapsed
- Equipment may now operate in automatic mode
- Remains in this state while conditions are met

**Action:** Equipment can execute its automatic operation

## Startup Sequence

```
┌─────────────┐
│ NotReleased │ ◄─── Initial state
└──────┬──────┘      Not in Auto mode, or not released, or has error
       │
       │ Conditions met:
       │ - Automatic mode
       │ - Released (no safety issues)
       │ - No errors
       │
       ▼
┌──────────────────┐
│ AutoStartingUp   │ ◄─── Warning phase
└──────┬───────────┘      Timer running (e.g., 5 seconds)
       │                  Show warnings, prepare equipment
       │
       │ Timer elapsed
       │
       ▼
┌──────────────────┐
│ AutoStartedUp    │ ◄─── Fully operational
└──────────────────┘      Equipment can operate automatically
```

## Configuration

### StartUpTime Property

Configure the warning duration on the equipment:

```iec-st
// Default: 5 seconds
equipment.StartUpTime := T#5s;

// Longer warning for large equipment
equipment.StartUpTime := T#10s;

// Shorter warning for small equipment
equipment.StartUpTime := T#3s;
```

### Checking Startup Status

```iec-st
VAR
    status : StartUpStatus;
END_VAR

status := equipment.GetStartupStatus();

CASE status OF
    StartUpStatus#InternalError:
        // Configuration error - check Mode assignment
        ;
    StartUpStatus#NotReleased:
        // Not ready to start - check conditions
        ;
    StartUpStatus#AutoStartingUp:
        // Warning phase - show warnings
        ActivateWarningLight := TRUE;
        ;
    StartUpStatus#AutoStartedUp:
        // Fully started - operate equipment
        ActivateWarningLight := FALSE;
        RunEquipment := TRUE;
        ;
END_CASE;
```

## Usage Examples

### Basic Startup Handling

```iec-st
CLASS MyConveyor EXTENDS EquipmentBase
    VAR PUBLIC
        Running : BOOL;
        WarningLight : BOOL;
    END_VAR
    
    METHOD PROTECTED OVERRIDE RunCyclicUserCode
        CASE THIS.GetStartupStatus() OF
            StartUpStatus#NotReleased:
                Running := FALSE;
                WarningLight := FALSE;
                
            StartUpStatus#AutoStartingUp:
                Running := FALSE;
                WarningLight := TRUE;  // Warn operators
                
            StartUpStatus#AutoStartedUp:
                Running := TRUE;
                WarningLight := FALSE;
                
            StartUpStatus#InternalError:
                Running := FALSE;
                WarningLight := FALSE;
                THIS.SetError(ErrorState#ConfigError);
        END_CASE;
    END_METHOD
END_CLASS
```

### Startup with Speed Ramping

```iec-st
CLASS MyConveyor EXTENDS EquipmentBase
    VAR PUBLIC
        Speed : REAL;
        TargetSpeed : REAL := 100.0;
    END_VAR
    VAR PRIVATE
        rampRate : REAL := 10.0;  // Units per second
    END_VAR
    
    METHOD PROTECTED OVERRIDE RunCyclicUserCode
        CASE THIS.GetStartupStatus() OF
            StartUpStatus#NotReleased,
            StartUpStatus#AutoStartingUp:
                // Ramp down during warning
                IF Speed > 0.0 THEN
                    Speed := Speed - rampRate * 0.01;  // Assuming 10ms cycle
                    IF Speed < 0.0 THEN
                        Speed := 0.0;
                    END_IF;
                END_IF;
                
            StartUpStatus#AutoStartedUp:
                // Ramp up to target speed
                IF Speed < TargetSpeed THEN
                    Speed := Speed + rampRate * 0.01;
                    IF Speed > TargetSpeed THEN
                        Speed := TargetSpeed;
                    END_IF;
                END_IF;
        END_CASE;
    END_METHOD
END_CLASS
```

### Startup with Interlocks

```iec-st
CLASS MyEquipment EXTENDS EquipmentBase
    VAR PUBLIC
        UpstreamReady : BOOL;
        DownstreamReady : BOOL;
    END_VAR
    
    METHOD PROTECTED OVERRIDE RunCyclicUserCode
        VAR
            canOperate : BOOL;
        END_VAR
        
        // Check startup status
        IF THIS.GetStartupStatus() <> StartUpStatus#AutoStartedUp THEN
            // Not started up yet
            canOperate := FALSE;
        ELSE
            // Started up, check interlocks
            canOperate := UpstreamReady AND DownstreamReady;
        END_IF;
        
        IF canOperate THEN
            // Execute equipment logic
        ELSE
            // Stop equipment
        END_IF;
    END_METHOD
END_CLASS
```

## Custom Startup Implementation

You can provide a custom startup implementation via `ExternalAutoStartup`:

```iec-st
CLASS CustomStartup IMPLEMENTS ItfAutoStartup
    VAR PUBLIC
        CustomStartupTime : TIME := T#15s;
        // Custom logic here
    END_VAR
    
    METHOD PUBLIC Status : StartUpStatus
        // Implement custom startup logic
    END_METHOD
    
    METHOD PUBLIC RunCyclic
        // Implement custom startup behavior
    END_METHOD
END_CLASS

// Usage
equipment.ExternalAutoStartup := customStartup;
```

## Best Practices

1. **Set appropriate startup times**: Based on equipment size and safety requirements
   ```iec-st
   // Large equipment: longer warning
   bigConveyor.StartUpTime := T#10s;
   
   // Small equipment: shorter warning
   smallActuator.StartUpTime := T#3s;
   ```

2. **Always check startup status**: Before activating equipment
   ```iec-st
   IF (THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp) THEN
       // Safe to operate
   END_IF;
   ```

3. **Provide visual/audible warnings**: During AutoStartingUp phase
   ```iec-st
   WarningLight := (THIS.GetStartupStatus() = StartUpStatus#AutoStartingUp);
   ```

4. **Handle InternalError**: Check configuration
   ```iec-st
   IF (THIS.GetStartupStatus() = StartUpStatus#InternalError) THEN
       // Mode not assigned or other configuration issue
   END_IF;
   ```

5. **Respect the warning phase**: Don't bypass it
   ```iec-st
   // ✓ Correct - respect startup status
   IF (THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp) THEN
       RunMotor := TRUE;
   END_IF;
   
   // ✗ Wrong - bypasses safety warning
   RunMotor := TRUE;  // Always on
   ```

## Startup Conditions

Equipment will only start automatically when **ALL** conditions are met:

1. ✓ Operating mode is `Automatic`
2. ✓ External release is TRUE (or NULL)
3. ✓ Equipment has no errors
4. ✓ Startup timer has elapsed

If any condition is lost during startup, the process resets to `NotReleased`.

## See Also

- [EquipmentBase](EquipmentBase.md) - Equipment base class
- [Release Management](Release.md) - External release control
- [Operating Modes](OperatingModes.md) - Operating mode management
- [Error States](ErrorStates.md) - Error handling
