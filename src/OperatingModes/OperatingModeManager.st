NAMESPACE Simatic.Ax.AutomationBase

    {axcode:docs-v0:@simatic-ax/automationbase:OperatingModes.md}
    /// Generic operating mode manager class
    /// Provides a simple implementation of IOperatingMode with settable mode
    CLASS OperatingModeManager IMPLEMENTS IOperatingMode
        VAR PROTECTED
            /// Current operating mode (default: Manual)
            _currentMode : OperatingModes := OperatingModes#Manual;
        END_VAR
        
        /// Returns the current operating mode
        METHOD PUBLIC GetOperatingMode : OperatingModes
            GetOperatingMode := _currentMode;
        END_METHOD
        
        /// Sets the operating mode
        METHOD PUBLIC SetOperatingMode
            VAR_INPUT
                mode : OperatingModes;
            END_VAR
            _currentMode := mode;
        END_METHOD
        
    END_CLASS

END_NAMESPACE
