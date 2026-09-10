NAMESPACE Simatic.Ax.AutomationBase
    
    {axcode:docs-v0:@simatic-ax/automationbase:Release.md}
    /// Interface for release providers
    /// Implement this to control when equipment is allowed to start
    /// Used for safety interlocks, upstream dependencies, etc.
    INTERFACE IRelease
        /// Returns TRUE when equipment is released and allowed to operate
        METHOD IsReleased : BOOL
        END_METHOD
    END_INTERFACE

END_NAMESPACE


