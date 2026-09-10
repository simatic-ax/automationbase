# @simatic-ax/automation-base

## Description

The **Automation Base** library provides a comprehensive foundation for building industrial automation applications with SIMATIC AX. It offers base classes, interfaces, and utilities for managing equipment initialization and cyclic execution, operating modes, error handling, automatic startup sequences, and signal supervision.

## Key Features

- **Equipment Management**: Abstract base classes for standardized equipment initialization and cyclic execution
- **Operating Modes**: Support for Commissioning, Manual, and Automatic modes
- **Auto-Startup**: Configurable automatic startup with safety warning timers
- **Error Handling**: Structured error state management
- **Release Management**: External release control for safety interlocks
- **Supervision**: Time-based signal monitoring for sensors and actuators
- **Logging**: Flexible logging system with multiple log levels
- **Interface-Based Design**: Easy customization and testing

## Getting Started

### Installation

Install with Apax:

> If not yet done, login to the GitHub registry first.
> More information: [Personal Access Token Guide](https://github.com/simatic-ax/.github/blob/main/docs/personalaccesstoken.md)

```cli
apax add @simatic-ax/automationbase
```

### Basic Usage

Add the namespace in your ST code:

```iec-st
USING Simatic.Ax.AutomationBase;
```

### Minimal Working Example

```iec-st
USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.AutomationBase.Tests.ApplicationExample_01

CLASS MyConveyor EXTENDS EquipmentBase
    VAR PUBLIC
        Speed : LREAL;
        Running : BOOL;
    END_VAR
    
    METHOD PROTECTED OVERRIDE InitUser
        // Start from a safe idle state.
        Speed := 0.0;
        Running := FALSE;
    END_METHOD
    
    METHOD PROTECTED OVERRIDE RunCyclicUserCode
        IF (THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp) THEN
            // Only run the conveyor after automatic startup completed.
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

PROGRAM ConveyorDemo
    VAR
        modeProvider : OperatingModeManager;
        releaseByBool : BoolRelease;
        conveyor : MyConveyor;
    END_VAR

    // Wire the dependencies exactly as in ApplicationExample_01.
    conveyor.Mode := modeProvider;
    conveyor.ExternalRelease := releaseByBool;
    conveyor.StartUpTime := T#0s;

    // Automatic mode plus release starts the conveyor immediately.
    modeProvider.SetOperatingMode(mode := OperatingModes#Automatic);

    releaseByBool.ReleaseSignal := TRUE;
    conveyor.RunCyclic();

    // Removing the release stops the conveyor in the next cycle.
    releaseByBool.ReleaseSignal := FALSE;
    conveyor.RunCyclic();
END_PROGRAM

END_NAMESPACE
```

This example shows the minimum contract for `EquipmentBase`:

- assign `Mode` before the first `RunCyclic()` call
- assign `ExternalRelease` if startup should depend on a release condition
- call `RunCyclic()` every PLC cycle
- override `InitUser()`, `RunCyclicUserCode()`, and `ResetFaultUser()` in derived equipment classes
- use `GetStartupStatus()` to gate actuator logic until startup is complete
- expect the equipment to return to `NotReleased` and stop again if the release is withdrawn during operation

## Documentation

### Core Concepts

| Topic | Description |
|-------|-------------|
| [Equipment Base](docs/EquipmentBase.md) | Abstract base class for all equipment with initialization and cyclic execution |
| [Operating Modes](docs/OperatingModes.md) | Commissioning, Manual, and Automatic mode management |
| [Startup Warning](docs/StartupWarning.md) | Automatic startup sequences with configurable warning times |
| [Release Management](docs/Release.md) | External release control for safety interlocks |
| [Supervision](docs/Supervision.md) | Time-based signal monitoring for sensors and actuators |

### Public API Overview

The library is organized around a small set of public contracts:

- `EquipmentBase`: base class for reusable equipment logic with initialization, cyclic execution, startup handling, and fault reset
- `IEquipmentBase`: common equipment lifecycle interface
- `IOperatingMode`: provides the current operating mode to equipment
- `IRelease`: provides an external release or interlock signal
- `BoolRelease` and `BinSignalRelease`: ready-to-use `IRelease` implementations for `BOOL` and `IBinSignal` sources
- `IResetCommand`: provides centralized reset requests and error reporting
- `Supervision`: monitors time-based action and reaction conditions
- `ILogger` and `RingBufferLogger`: logging abstraction and in-memory logger implementation

### API Reference

#### Classes

| Class | Description | Documentation |
|-------|-------------|---------------|
| `EquipmentBase` | Abstract base class for equipment | [Details](docs/EquipmentBase.md) |
| `BoolRelease` | Simple release implementation based on a `BOOL` | [Details](docs/Release.md) |
| `BinSignalRelease` | Release implementation based on an `IBinSignal` | [Details](docs/Release.md) |
| `Supervision` | Time-based signal monitoring | [Details](docs/Supervision.md) |
| `RingBufferLogger` | Ring buffer based logger | Source in `src/Logging/RingBufferLogger.st` |

#### Interfaces

| Interface | Description | Documentation |
|-----------|-------------|---------------|
| `IEquipmentBase` | Equipment contract | [Details](docs/EquipmentBase.md) |
| `IRelease` | Release provider interface | [Details](docs/Release.md) |
| `IOperatingMode` | Operating mode provider | [Details](docs/OperatingModes.md) |
| `IResetCommand` | Reset command provider | Source in `src/Equipment/IResetCommand.st` |
| `ILogger` | Logger interface | Source in `src/Logging/ILogger.st` |

#### Types

| Type | Description | Documentation |
|------|-------------|---------------|
| `OperatingModes` | Enum: Commissioning, Manual, Automatic | [Details](docs/OperatingModes.md) |
| `StartUpStatus` | Enum: InternalError, NotReleased, Manual, AutoStartingUp, AutoStartedUp | [Details](docs/StartupWarning.md) |
| `ErrorState` | Error codes: NoError, ConfigError, OtherError | [Details](docs/EquipmentBase.md#error-handling) |
| `SupervisionBehavior` | Enum: Action, Reaction | [Details](docs/Supervision.md) |
| `LogLevel` | Enum: Info, Warning, Error, Debug | Source in `src/Logging/LogLevel.st` |

## Architecture

The library is organized into modules:

- **Equipment**: Base classes and interfaces for equipment management
- **Operating Modes**: Operating mode management and interfaces
- **Supervisions**: Signal monitoring and timeout detection
- **Logging**: Logging infrastructure with multiple implementations

## Examples

Example implementations are provided in the `examples/` directory:

- `ApplicationExample_01/` - BoolRelease-gated `MyConveyor` application example with matching AxUnit tests
- `ServoAxisExample.st` - Servo axis supervision flow
- `PneumaticCylinderExample.st` - Pneumatic cylinder control
- `LoggingExample.st` - Logging integration
- `SupervisionExample.st` - Signal supervision patterns
- `ResetCommandExample.st` - Centralized reset handling

Use the examples as integration patterns, then adapt the interfaces and timing parameters to your machine. The examples are not a substitute for assigning the required public dependencies such as `Mode` before cyclic execution starts.

Application examples in the `ApplicationExample_0x` format contain a local README, runnable ST code, and matching tests. Promote snippets from these examples into this README only after the corresponding tests pass.

## Best Practices

1. **Always assign Mode**: The `Mode` property is mandatory for equipment
   ```iec-st
   equipment.Mode := modeManager;
   ```

2. **Use ExternalRelease for safety**: Integrate safety systems
   ```iec-st
   equipment.ExternalRelease := safetyRelease;
   ```

    For simple cases, you can use the built-in release helpers:
    ```iec-st
    boolRelease.ReleaseSignal := machineEnabled;
    equipment.ExternalRelease := boolRelease;

    equipment.RunCyclic();

    boolRelease.ReleaseSignal := FALSE;
    equipment.RunCyclic();
    ```

    ```iec-st
    binSignalRelease.ReleaseSignal := releaseInput;
    equipment.ExternalRelease := binSignalRelease;
    ```

3. **Override protected methods only**: Use `InitUser()` and `RunCyclicUserCode()`
   ```iec-st
   METHOD PROTECTED OVERRIDE InitUser
   METHOD PROTECTED OVERRIDE RunCyclicUserCode
   ```

4. **Check startup status**: Before activating equipment
   ```iec-st
   IF (THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp) THEN
       // Safe to activate
   END_IF;
   ```

5. **Set appropriate startup times**: Based on safety requirements
   ```iec-st
   equipment.StartUpTime := T#10s;
   ```

If `ExternalRelease` is not assigned, `EquipmentBase` falls back to the internal `AlwaysReleasedRelease` implementation. See [docs/Release.md](docs/Release.md) for the available release strategies.

## Testing

The framework includes unit and integration tests in the `test/` directory with mock implementations for reference. Use them to understand expected behavior for startup, reset handling, supervision, and logging.

## Contribution

Thanks for your interest in contributing. Anybody is free to report bugs, unclear documentation, and other problems regarding this repository in the Issues section or, even better, propose changes using a pull request.

## License and Legal Information

Please read the [Legal information](LICENSE.md)
