NAMESPACE Simatic.Ax.AutomationBase

    {axcode:docs-v0:@simatic-ax/automationbase:OperatingModes.md}
    /// Interface for operating mode providers
    /// Implement this to provide the current operating mode to equipment
    INTERFACE IOperatingMode
        /// Returns the current operating mode (Commissioning, Manual, or Automatic)
        METHOD GetOperatingMode : OperatingModes
        END_METHOD
    END_INTERFACE

END_NAMESPACE
