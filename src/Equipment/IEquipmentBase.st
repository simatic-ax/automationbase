NAMESPACE Simatic.Ax.AutomationBase

    {axcode:docs-v0:@simatic-ax/automationbase:EquipmentBase.md}
    /// Interface for equipment base functionality
    /// Defines the contract for equipment lifecycle management
    INTERFACE IEquipmentBase
        /// Main cyclic method - must be called every PLC cycle
        METHOD RunCyclic
        END_METHOD
        
        /// Returns TRUE if equipment has an error
        METHOD HasError : BOOL
        END_METHOD
        
        /// Returns the current error code
        METHOD GetError : WORD
        END_METHOD
        
        /// Sets an error state
        METHOD SetError
            VAR_INPUT
                errorState : WORD;
            END_VAR
        END_METHOD
        
        /// Sets an error state with error text
        METHOD SetError
            VAR_INPUT
                errorState : WORD;
                errorText : STRING[30];
            END_VAR
        END_METHOD
        
        /// Returns the last error message
        METHOD GetErrorText : STRING[30]
        END_METHOD
        
        /// Returns the current startup status
        METHOD GetStartupStatus : StartUpStatus
        END_METHOD
        
        /// Resets the fault state and clears error message
        METHOD ResetFault
        END_METHOD
    END_INTERFACE

END_NAMESPACE
