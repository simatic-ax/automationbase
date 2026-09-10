# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `SetError` method overload with `errorText` parameter (STRING[30]) to provide descriptive error messages
- `GetErrorText()` method to retrieve the last error message
- `ResetFault()` method to clear error state and error message
- Error message storage in `EquipmentBase` class (`_errorText` protected variable)
- Comprehensive tests for new error handling functionality

### Changed
- **BREAKING**: Renamed all interface files and types from `Itf*` prefix to `I*` prefix for better naming convention:
  - `ItfEquipmentBase` → `IEquipmentBase`
  - `ItfRelease` → `IRelease`
  - `ItfOperatingMode` → `IOperatingMode`
  - `ItfLogger` → `ILogger`
  - `ItfAutoStartup` → `IAutoStartup`
- `GetError()` method now returns the actual error state instead of always returning `NoError`
- `SetError(errorState)` now clears the error text when called without text parameter

### Removed
- **BREAKING**: `ResetActive()` method removed from `IEquipmentBase` interface and `EquipmentBase` class
  - Use `ResetFault()` method instead for error reset functionality

### Fixed
- Error state is now properly tracked and returned by `GetError()` method

## Migration Guide

### Interface Renaming
Update all interface references in your code:
```iec-st
// Old
VAR
    equipment : ItfEquipmentBase;
    mode : ItfOperatingMode;
    release : ItfRelease;
END_VAR

// New
VAR
    equipment : IEquipmentBase;
    mode : IOperatingMode;
    release : IRelease;
END_VAR
```

### ResetActive Removal
Replace `ResetActive()` calls with `ResetFault()`:
```iec-st
// Old
IF equipment.ResetActive() THEN
    // Handle reset
END_IF;

// New
equipment.ResetFault();  // Directly resets the fault
```

### Enhanced Error Handling
Take advantage of the new error text functionality:
```iec-st
// Set error with descriptive text
equipment.SetError(errorState := ErrorState#OtherError, 
                   errorText := 'Motor temperature too high');

// Retrieve error information
IF equipment.HasError() THEN
    errorCode := equipment.GetError();
    errorMessage := equipment.GetErrorText();
    // Display or log error information
END_IF;

// Clear error when resolved
equipment.ResetFault();
```
