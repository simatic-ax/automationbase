# Operating Modes

## Overview

The Operating Modes system provides a standardized way to manage different operational states of equipment in SIMATIC AX applications. It defines three distinct modes that control equipment behavior and automation level.

## OperatingModes Enumeration

```iec-st
TYPE OperatingModes : (
    Commissioning,      // Initial setup and testing mode
    Manual,            // Manual operation mode
    Automatic          // Automatic operation mode
) := Manual;
```

## Mode Descriptions

### Commissioning
**Purpose:** Initial setup, testing, and commissioning activities

**Characteristics:**
- Equipment can be tested individually
- Safety interlocks may be bypassed (with appropriate safeguards)
- Typically used during installation and maintenance
- No automatic startup

**Use Cases:**
- Initial equipment installation
- Maintenance and repair
- Individual component testing
- Parameter tuning

### Manual
**Purpose:** Manual operation with operator control

**Characteristics:**
- Equipment requires manual activation
- No automatic startup
- Full operator control
- All safety interlocks active
- **Default mode**

**Use Cases:**
- Manual production runs
- Operator training
- Troubleshooting
- Setup and changeover

### Automatic
**Purpose:** Fully automatic operation

**Characteristics:**
- Equipment starts automatically when released
- Automatic startup warning sequence
- Minimal operator intervention
- Process-driven operation

**Use Cases:**
- Normal production operation
- Automated manufacturing
- Continuous processes
- Lights-out operation

## ItfOperatingMode Interface

```iec-st
INTERFACE ItfOperatingMode
    METHOD GetOperatingMode : OperatingModes
    END_METHOD
END_INTERFACE
```

### GetOperatingMode() : OperatingModes

Returns the current operating mode of the system.

**Returns:** Current operating mode (Commissioning, Manual, or Automatic)

## Implementation Example

### Basic Operating Mode Manager

```iec-st
USING Simatic.Ax.AutomationBase;

CLASS OperatingModeManager IMPLEMENTS ItfOperatingMode
    VAR PUBLIC
        CurrentMode : OperatingModes := OperatingModes#Manual;
    END_VAR
    
    METHOD PUBLIC GetOperatingMode : OperatingModes
        GetOperatingMode := CurrentMode;
    END_METHOD
END_CLASS
```

### HMI-Controlled Operating Mode

```iec-st
USING Simatic.Ax.AutomationBase;

CLASS HMIOperatingMode IMPLEMENTS ItfOperatingMode
    VAR PUBLIC
        HMI_ModeSelection : INT;  // 0=Commissioning, 1=Manual, 2=Automatic
        HMI_ModeChangeRequest : BOOL;
        HMI_ModeChangeAck : BOOL;
    END_VAR
    VAR PRIVATE
        _currentMode : OperatingModes := OperatingModes#Manual;
        _modeChangeAllowed : BOOL := TRUE;
    END_VAR
    
    METHOD PUBLIC GetOperatingMode : OperatingModes
        GetOperatingMode := _currentMode;
    END_METHOD
    
    METHOD PUBLIC RunCyclic
        // Handle mode change requests from HMI
        IF HMI_ModeChangeRequest AND _modeChangeAllowed THEN
            CASE HMI_ModeSelection OF
                0: _currentMode := OperatingModes#Commissioning;
                1: _currentMode := OperatingModes#Manual;
                2: _currentMode := OperatingModes#Automatic;
            END_CASE;
            HMI_ModeChangeAck := TRUE;
        ELSE
            HMI_ModeChangeAck := FALSE;
        END_IF;
    END_METHOD
END_CLASS
```

### Conditional Mode Manager

```iec-st
USING Simatic.Ax.AutomationBase;

CLASS ConditionalModeManager IMPLEMENTS ItfOperatingMode
    VAR PUBLIC
        RequestedMode : OperatingModes := OperatingModes#Manual;
        AllEquipmentReady : BOOL;
        SafetySystemOK : BOOL;
    END_VAR
    VAR PRIVATE
        _activeMode : OperatingModes := OperatingModes#Manual;
    END_VAR
    
    METHOD PUBLIC GetOperatingMode : OperatingModes
        GetOperatingMode := _activeMode;
    END_METHOD
    
    METHOD PUBLIC RunCyclic
        // Only allow Automatic mode if conditions are met
        IF RequestedMode = OperatingModes#Automatic THEN
            IF AllEquipmentReady AND SafetySystemOK THEN
                _activeMode := OperatingModes#Automatic;
            ELSE
                _activeMode := OperatingModes#Manual;  // Fall back to Manual
            END_IF;
        ELSE
            _activeMode := RequestedMode;
        END_IF;
    END_METHOD
END_CLASS
```

## Usage with Equipment

### Basic Integration

```iec-st
PROGRAM MyApplication
    VAR
        modeManager : OperatingModeManager;
        conveyor : MyConveyor;
    END_VAR
    
    // Assign mode manager to equipment (mandatory!)
    conveyor.Mode := modeManager;
    
    // Change operating mode
    modeManager.CurrentMode := OperatingModes#Automatic;
    
    // Run equipment
    conveyor.RunCyclic();
END_PROGRAM
```

### Mode-Dependent Behavior

```iec-st
CLASS MyConveyor EXTENDS EquipmentBase
    VAR PUBLIC
        Speed : REAL;
        ManualSpeedSetpoint : REAL;
        AutomaticSpeedSetpoint : REAL;
    END_VAR
    
    METHOD PROTECTED OVERRIDE RunCyclicUserCode
        CASE Mode.GetOperatingMode() OF
            OperatingModes#Commissioning:
                // Commissioning mode - allow manual control with diagnostics
                Speed := ManualSpeedSetpoint;
                // Enable additional diagnostics
                
            OperatingModes#Manual:
                // Manual mode - operator controlled
                Speed := ManualSpeedSetpoint;
                
            OperatingModes#Automatic:
                // Automatic mode - process controlled
                IF THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp THEN
                    Speed := AutomaticSpeedSetpoint;
                ELSE
                    Speed := 0.0;
                END_IF;
        END_CASE;
    END_METHOD
END_CLASS
```

## Mode Transitions

### Safe Mode Transitions

```
┌────────────────┐
│ Commissioning  │
└───────┬────────┘
        │
        ├──────────────┐
        │              │
        ▼              ▼
┌────────────┐   ┌────────────┐
│   Manual   │◄─►│ Automatic  │
└────────────┘   └────────────┘
```

**Recommended transition logic:**
1. Always transition through Manual when changing between Commissioning and Automatic
2. Ensure equipment is stopped before mode changes
3. Verify safety conditions before entering Automatic mode

### Transition Implementation

```iec-st
CLASS SafeModeManager IMPLEMENTS ItfOperatingMode
    VAR PUBLIC
        RequestedMode : OperatingModes;
        AllEquipmentStopped : BOOL;
    END_VAR
    VAR PRIVATE
        _currentMode : OperatingModes := OperatingModes#Manual;
    END_VAR
    
    METHOD PUBLIC GetOperatingMode : OperatingModes
        GetOperatingMode := _currentMode;
    END_METHOD
    
    METHOD PUBLIC RunCyclic
        // Only allow mode change when equipment is stopped
        IF AllEquipmentStopped THEN
            // Direct transitions allowed
            IF RequestedMode = OperatingModes#Manual THEN
                _currentMode := OperatingModes#Manual;
            ELSIF RequestedMode = OperatingModes#Commissioning THEN
                _currentMode := OperatingModes#Commissioning;
            ELSIF RequestedMode = OperatingModes#Automatic THEN
                // Additional checks for Automatic mode
                IF _currentMode = OperatingModes#Manual THEN
                    _currentMode := OperatingModes#Automatic;
                END_IF;
            END_IF;
        END_IF;
    END_METHOD
END_CLASS
```

## Impact on Equipment Behavior

### Automatic Startup

Automatic startup **only occurs in Automatic mode**:

```iec-st
// In Automatic mode with release
GetStartupStatus() = StartUpStatus#AutoStartingUp  // Warning phase
GetStartupStatus() = StartUpStatus#AutoStartedUp   // Fully started

// In Manual or Commissioning mode
GetStartupStatus() = StartUpStatus#NotReleased     // No automatic startup
```

### Equipment Activation

```iec-st
METHOD PROTECTED OVERRIDE RunCyclicUserCode
    CASE Mode.GetOperatingMode() OF
        OperatingModes#Commissioning,
        OperatingModes#Manual:
            // Manual activation required
            IF ManualStartButton THEN
                ActivateEquipment := TRUE;
            END_IF;
            
        OperatingModes#Automatic:
            // Automatic activation based on startup status
            IF THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp THEN
                ActivateEquipment := TRUE;
            END_IF;
    END_CASE;
END_METHOD
```

## Best Practices

1. **Always assign Mode to equipment**: It's mandatory
   ```iec-st
   equipment.Mode := modeManager;  // Required!
   ```

2. **Use Manual as default**: Safest starting point
   ```iec-st
   CurrentMode : OperatingModes := OperatingModes#Manual;
   ```

3. **Verify conditions before Automatic**: Check safety and readiness
   ```iec-st
   IF AllSafetyConditionsMet AND EquipmentReady THEN
       modeManager.CurrentMode := OperatingModes#Automatic;
   END_IF;
   ```

4. **Stop equipment before mode changes**: Prevent unsafe transitions
   ```iec-st
   IF AllEquipmentStopped THEN
       // Safe to change mode
   END_IF;
   ```

5. **Implement mode-specific behavior**: Tailor equipment response
   ```iec-st
   CASE Mode.GetOperatingMode() OF
       OperatingModes#Commissioning:
           // Special commissioning behavior
       OperatingModes#Manual:
           // Manual operation
       OperatingModes#Automatic:
           // Automatic operation
   END_CASE;
   ```

6. **Use Commissioning mode carefully**: Ensure proper safeguards
   ```iec-st
   IF Mode.GetOperatingMode() = OperatingModes#Commissioning THEN
       // Enable commissioning features
       // Ensure appropriate safety measures
   END_IF;
   ```

## Common Patterns

### Zone-Level Mode Management

```iec-st
CLASS ZoneModeManager IMPLEMENTS ItfOperatingMode
    VAR PUBLIC
        ZoneMode : OperatingModes := OperatingModes#Manual;
        Equipment1, Equipment2, Equipment3 : ItfEquipmentBase;
    END_VAR
    
    METHOD PUBLIC GetOperatingMode : OperatingModes
        GetOperatingMode := ZoneMode;
    END_METHOD
    
    METHOD PUBLIC SetZoneMode
        VAR_INPUT
            newMode : OperatingModes;
        END_VAR
        // Set mode for entire zone
        ZoneMode := newMode;
    END_METHOD
END_CLASS
```

### Mode with Permissions

```iec-st
CLASS PermissionBasedMode IMPLEMENTS ItfOperatingMode
    VAR PUBLIC
        RequestedMode : OperatingModes;
        UserHasCommissioningPermission : BOOL;
        UserHasAutomaticPermission : BOOL;
    END_VAR
    VAR PRIVATE
        _activeMode : OperatingModes := OperatingModes#Manual;
    END_VAR
    
    METHOD PUBLIC GetOperatingMode : OperatingModes
        GetOperatingMode := _activeMode;
    END_METHOD
    
    METHOD PUBLIC RunCyclic
        CASE RequestedMode OF
            OperatingModes#Commissioning:
                IF UserHasCommissioningPermission THEN
                    _activeMode := OperatingModes#Commissioning;
                END_IF;
                
            OperatingModes#Automatic:
                IF UserHasAutomaticPermission THEN
                    _activeMode := OperatingModes#Automatic;
                END_IF;
                
            OperatingModes#Manual:
                _activeMode := OperatingModes#Manual;  // Always allowed
        END_CASE;
    END_METHOD
END_CLASS
```

## See Also

- [EquipmentBase](EquipmentBase.md) - Equipment base class
- [Startup Warning](StartupWarning.md) - Automatic startup behavior
- [Release Management](Release.md) - External release control
