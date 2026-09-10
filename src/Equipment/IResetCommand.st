NAMESPACE Simatic.Ax.AutomationBase

    /// Interface for reset command providers
    /// Implement this to provide centralized reset commands to equipment
    INTERFACE IResetCommand
        /// Returns TRUE when a reset command is active
        /// Equipment calls this to check if reset should be attempted
        METHOD ResetFaultRequest : BOOL
        END_METHOD
        
        /// Equipment calls this to report it has an active error
        /// Call this every cycle when equipment has an error
        METHOD ReportError
        END_METHOD
        
    END_INTERFACE

END_NAMESPACE
