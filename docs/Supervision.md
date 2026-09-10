# Supervision

## Overview

The `Supervision` class provides time-based signal monitoring for SIMATIC AX applications. It monitors whether a signal reaches an expected state within a configurable timeout period, making it ideal for detecting stuck sensors, failed actuators, or process timeouts.

## Purpose

Supervision is used to:
- Monitor sensor responses (e.g., "Did the sensor activate within 5 seconds?")
- Verify actuator reactions (e.g., "Did the motor stop within 3 seconds?")
- Detect process timeouts (e.g., "Did the valve close within 10 seconds?")
- Implement safety monitoring with time constraints

## Class Declaration

```iec-st
CLASS Supervision
```

## Public Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `timeout` | TIME | T#5s | Maximum time allowed for signal to reach expected state |
| `behavior` | SupervisionBehavior | Action | Supervision type: Action (signal must become TRUE) or Reaction (signal must become FALSE) |

## SupervisionBehavior Enumeration

```iec-st
TYPE SupervisionBehavior : (
    Action,        // Signal must become TRUE (e.g., sensor activates)
    Reaction       // Signal must become FALSE (e.g., sensor deactivates)
) := Action;
```

## SupervisionError Enumeration

```iec-st
TYPE SupervisionError : (
    NO_ERROR,      // No error - supervision successful or not yet started
    TIMEOUT        // Timeout - signal did not reach expected state in time
) := NO_ERROR;
```

## Public Methods

### Start()
Starts the supervision monitoring. Must be called to activate supervision.

```iec-st
METHOD PUBLIC Start
```

**Effect:**
- Activates supervision
- Resets completion flag
- Clears any previous errors
- Resets internal timer

### Stop()
Stops the supervision monitoring.

```iec-st
METHOD PUBLIC Stop
```

**Effect:**
- Deactivates supervision
- Clears error status
- Resets internal timer

### Execute(signal : BOOL)
Cyclic execution of supervision logic. Must be called every PLC cycle.

```iec-st
METHOD PUBLIC Execute
    VAR_INPUT
        signal : BOOL;  // The signal to monitor
    END_VAR
END_METHOD
```

**Parameters:**
- `signal`: The boolean signal to monitor

**Behavior:**
- If not active: Does nothing
- If already completed or error: Does nothing
- Otherwise: Monitors signal and checks timeout

### GetError() : SupervisionError
Returns the current error status.

```iec-st
METHOD PUBLIC GetError : SupervisionError
```

**Returns:** `NO_ERROR` or `TIMEOUT`

### HasError() : BOOL
Checks if an error exists.

```iec-st
METHOD PUBLIC HasError : BOOL
```

**Returns:** TRUE if error exists (timeout occurred)

### Reset()
Resets the error and stops the supervision.

```iec-st
METHOD PUBLIC Reset
```

**Effect:**
- Clears error status
- Stops supervision

### IsActive() : BOOL
Returns whether the supervision is currently active.

```iec-st
METHOD PUBLIC IsActive : BOOL
```

**Returns:** TRUE if supervision is monitoring

### IsCompleted() : BOOL
Returns whether the supervision has successfully completed.

```iec-st
METHOD PUBLIC IsCompleted : BOOL
```

**Returns:** TRUE if expected state was reached within timeout

## Usage Examples

### Action Supervision (Sensor Must Activate)

```iec-st
USING Simatic.Ax.AutomationBase;

CLASS MyEquipment EXTENDS EquipmentBase
    VAR
        sensorSupervision : Supervision;
        sensorSignal : BOOL;
        startCommand : BOOL;
    END_VAR
    
    METHOD PROTECTED OVERRIDE InitUser
        // Configure supervision
        sensorSupervision.timeout := T#3s;
        sensorSupervision.behavior := SupervisionBehavior#Action;  // Sensor must become TRUE
    END_METHOD
    
    METHOD PROTECTED OVERRIDE RunCyclicUserCode
        // Start supervision when command is given
        IF startCommand THEN
            sensorSupervision.Start();
        END_IF;
        
        // Execute supervision every cycle
        sensorSupervision.Execute(signal := sensorSignal);
        
        // Check for timeout
        IF sensorSupervision.HasError() THEN
            THIS.SetError(ErrorState#OtherError);
            // Log: "Sensor did not activate within 3 seconds"
        END_IF;
        
        // Check for successful completion
        IF sensorSupervision.IsCompleted() THEN
            // Sensor activated successfully
            // Continue with next step
        END_IF;
    END_METHOD
END_CLASS
```

### Reaction Supervision (Actuator Must Stop)

```iec-st
USING Simatic.Ax.AutomationBase;

CLASS MotorControl EXTENDS EquipmentBase
    VAR
        stopSupervision : Supervision;
        motorRunning : BOOL;
        stopCommand : BOOL;
    END_VAR
    
    METHOD PROTECTED OVERRIDE InitUser
        // Configure supervision
        stopSupervision.timeout := T#5s;
        stopSupervision.behavior := SupervisionBehavior#Reaction;  // Motor must become FALSE (stopped)
    END_METHOD
    
    METHOD PROTECTED OVERRIDE RunCyclicUserCode
        // Start supervision when stop command is given
        IF stopCommand THEN
            stopSupervision.Start();
        END_IF;
        
        // Execute supervision every cycle
        stopSupervision.Execute(signal := motorRunning);
        
        // Check for timeout
        IF stopSupervision.HasError() THEN
            THIS.SetError(ErrorState#OtherError);
            // Log: "Motor did not stop within 5 seconds"
            // Trigger emergency stop
        END_IF;
        
        // Check for successful completion
        IF stopSupervision.IsCompleted() THEN
            // Motor stopped successfully
            stopCommand := FALSE;
        END_IF;
    END_METHOD
END_CLASS
```

### Multiple Supervisions

```iec-st
USING Simatic.Ax.AutomationBase;

CLASS CylinderControl EXTENDS EquipmentBase
    VAR
        extendSupervision : Supervision;
        retractSupervision : Supervision;
        extendedSensor : BOOL;
        retractedSensor : BOOL;
        extendCommand : BOOL;
        retractCommand : BOOL;
    END_VAR
    
    METHOD PROTECTED OVERRIDE InitUser
        // Extend supervision: Sensor must become TRUE
        extendSupervision.timeout := T#2s;
        extendSupervision.behavior := SupervisionBehavior#Action;
        
        // Retract supervision: Sensor must become TRUE
        retractSupervision.timeout := T#2s;
        retractSupervision.behavior := SupervisionBehavior#Action;
    END_METHOD
    
    METHOD PROTECTED OVERRIDE RunCyclicUserCode
        // Handle extend command
        IF extendCommand THEN
            extendSupervision.Start();
        END_IF;
        extendSupervision.Execute(signal := extendedSensor);
        
        IF extendSupervision.HasError() THEN
            THIS.SetError(ErrorState#OtherError);
            // Cylinder did not extend
        ELSIF extendSupervision.IsCompleted() THEN
            extendCommand := FALSE;
            // Cylinder extended successfully
        END_IF;
        
        // Handle retract command
        IF retractCommand THEN
            retractSupervision.Start();
        END_IF;
        retractSupervision.Execute(signal := retractedSensor);
        
        IF retractSupervision.HasError() THEN
            THIS.SetError(ErrorState#OtherError);
            // Cylinder did not retract
        ELSIF retractSupervision.IsCompleted() THEN
            retractCommand := FALSE;
            // Cylinder retracted successfully
        END_IF;
    END_METHOD
END_CLASS
```

### Supervision with Reset

```iec-st
USING Simatic.Ax.AutomationBase;

CLASS SupervisedProcess EXTENDS EquipmentBase
    VAR
        processSupervision : Supervision;
        processComplete : BOOL;
        startProcess : BOOL;
        resetButton : BOOL;
    END_VAR
    
    METHOD PROTECTED OVERRIDE InitUser
        processSupervision.timeout := T#30s;
        processSupervision.behavior := SupervisionBehavior#Action;
    END_METHOD
    
    METHOD PROTECTED OVERRIDE RunCyclicUserCode
        // Reset supervision on button press
        IF resetButton THEN
            processSupervision.Reset();
            THIS.SetError(ErrorState#NoError);
        END_IF;
        
        // Start supervision
        IF startProcess THEN
            processSupervision.Start();
        END_IF;
        
        // Execute supervision
        processSupervision.Execute(signal := processComplete);
        
        // Handle results
        IF processSupervision.HasError() THEN
            THIS.SetError(ErrorState#OtherError);
            // Process timeout - operator must reset
        ELSIF processSupervision.IsCompleted() THEN
            // Process completed successfully
            startProcess := FALSE;
        END_IF;
    END_METHOD
END_CLASS
```

## Supervision States

```
┌──────────────┐
│   Inactive   │ ◄─── Initial state, after Stop() or Reset()
└──────┬───────┘
       │
       │ Start() called
       │
       ▼
┌──────────────┐
│    Active    │ ◄─── Monitoring signal, timer running
└──────┬───────┘
       │
       ├─────────────────┐
       │                 │
       │ Signal reaches  │ Timeout occurs
       │ expected state  │
       │                 │
       ▼                 ▼
┌──────────────┐   ┌──────────────┐
│  Completed   │   │    Error     │
└──────────────┘   └──────────────┘
```

## Best Practices

1. **Configure before starting**: Set timeout and behavior before Start()
   ```iec-st
   supervision.timeout := T#5s;
   supervision.behavior := SupervisionBehavior#Action;
   supervision.Start();
   ```

2. **Call Execute() every cycle**: Required for proper timing
   ```iec-st
   supervision.Execute(signal := mySignal);
   ```

3. **Check completion and errors**: Handle both success and failure
   ```iec-st
   IF supervision.HasError() THEN
       // Handle timeout
   ELSIF supervision.IsCompleted() THEN
       // Handle success
   END_IF;
   ```

4. **Use appropriate timeouts**: Based on physical process
   ```iec-st
   // Fast actuator
   fastSupervision.timeout := T#500ms;
   
   // Slow process
   slowSupervision.timeout := T#30s;
   ```

5. **Reset after errors**: Allow retry after timeout
   ```iec-st
   IF resetButton THEN
       supervision.Reset();
   END_IF;
   ```

6. **Choose correct behavior**: Action vs Reaction
   ```iec-st
   // Sensor must activate
   supervision.behavior := SupervisionBehavior#Action;
   
   // Motor must stop
   supervision.behavior := SupervisionBehavior#Reaction;
   ```

## Common Patterns

### One-Shot Supervision

```iec-st
// Start once, check result
IF startCondition THEN
    supervision.Start();
END_IF;

supervision.Execute(signal := sensor);

IF supervision.IsCompleted() THEN
    // Success - proceed
ELSIF supervision.HasError() THEN
    // Timeout - handle error
END_IF;
```

### Retriable Supervision

```iec-st
// Allow multiple attempts
IF startCondition AND NOT supervision.IsActive() THEN
    supervision.Start();
END_IF;

supervision.Execute(signal := sensor);

IF supervision.HasError() THEN
    IF retryButton THEN
        supervision.Reset();
    END_IF;
END_IF;
```

### Continuous Supervision

```iec-st
// Monitor continuously while active
IF processRunning THEN
    IF NOT supervision.IsActive() THEN
        supervision.Start();
    END_IF;
    supervision.Execute(signal := healthSignal);
ELSE
    supervision.Stop();
END_IF;
```

## See Also

- [EquipmentBase](EquipmentBase.md) - Equipment base class integration
- [Error States](ErrorStates.md) - Error handling
