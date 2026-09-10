USING Simatic.Ax.IO.Input;

NAMESPACE Simatic.Ax.AutomationBase

    /// Simple and robust reset command manager
    /// Equipment reports errors via ReportError() every cycle while error is active
    /// Manager provides reset command that is active for exactly one cycle
    /// Reset is triggered on rising edge of ResetSignal
    CLASS ResetCommandManager IMPLEMENTS IResetCommand
        VAR PUBLIC
            /// Reset signal input (connect to HMI button or other signal source)
            /// Reset is triggered on rising edge via QRis()
            ResetSignal : IBinSignal;
        END_VAR
        
        VAR PRIVATE
            /// TRUE if any equipment has reported an error in current cycle
            _anyErrorIsActive : BOOL;
            
            /// TRUE if reset command is active (valid for exactly one cycle)
            _resetCommandActive : BOOL;
        END_VAR
        
        /// Call this every cycle to update reset command state
        /// Reset command is cleared at start and only set on rising edge of ResetSignal
        /// This ensures reset command is active for exactly one cycle
        METHOD PUBLIC RunCyclic
            // Clear reset command at start of cycle
            _resetCommandActive := FALSE;

            // Detect rising edge of reset signal and activate reset command
            IF (ResetSignal <> NULL AND ResetSignal.QRis()) THEN
                _resetCommandActive := TRUE;
                _anyErrorIsActive := FALSE; // Clear error flag on reset
            END_IF;
        END_METHOD
        
        /// Returns TRUE when a reset command is active
        /// Equipment calls this to check if reset should be attempted
        METHOD PUBLIC ResetFaultRequest : BOOL
            ResetFaultRequest := _resetCommandActive;
        END_METHOD
        
        /// Equipment calls this to report it has an active error
        /// Must be called every cycle while equipment has an error
        METHOD PUBLIC ReportError
            _anyErrorIsActive := TRUE;
        END_METHOD
        
        /// Returns TRUE if any equipment has reported an active error
        METHOD PUBLIC AnyErrorActive : BOOL
            AnyErrorActive := _anyErrorIsActive;
        END_METHOD
        
        /// Returns TRUE if reset command is currently active
        METHOD PUBLIC IsResetActive : BOOL
            IsResetActive := _resetCommandActive;
        END_METHOD
    END_CLASS

END_NAMESPACE
