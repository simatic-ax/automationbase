USING System.Timer;

NAMESPACE Simatic.Ax.AutomationBase

    /// Enum for supervision behavior
    TYPE
        SupervisionBehavior : (
            Action,        // Action supervision: Signal must become TRUE
            Reaction       // Reaction supervision: Signal must become FALSE
        ) := Action;
    END_TYPE

    /// Enum for supervision error types
    TYPE
        SupervisionError : (
            NO_ERROR,      // No error
            TIMEOUT   // Timeout: Signal did not reach expected state in time
        ) := NO_ERROR;
    END_TYPE

    {axcode:docs-v0:@simatic-ax/automationbase:Supervision.md}
    /// Generic supervision class for time-based signal monitoring
    /// Monitors whether a signal reaches an expected state within a configurable time
    CLASS Supervision
        
        //=============================================================================
        // PUBLIC VARIABLES (Configuration)
        //=============================================================================
        VAR PUBLIC
            /// Timeout for the supervision
            timeout : LTIME := T#5s;
            
            /// Supervision behavior
            /// Action: Signal must become TRUE (e.g. sensor becomes active)
            /// Reaction: Signal must become FALSE (e.g. sensor becomes inactive)
            behavior : SupervisionBehavior := SupervisionBehavior#Action;
        END_VAR
        
        //=============================================================================
        // PRIVATE VARIABLES (Internal state management)
        //=============================================================================
        VAR PRIVATE
            /// Debug: Counter for Start() calls
            _debugStartCounter : UDINT;
            
            /// Debug: Counter for Stop() calls
            _debugStopCounter : UDINT;
            
            /// Debug: Counter for Execute() calls
            _debugExecuteCounter : UDINT;
            
            /// Debug: Counter for completed supervisions
            _debugCompletedCounter : UDINT;
            
            /// Debug: Counter for timeout errors
            _debugTimeoutCounter : UDINT;
            
            /// Counter: How often _active was triggered
            _activeCounter : UDINT;
            
            /// Timer for supervision
            _timer : OnDelay;
            
            /// Current error status
            _error_status : SupervisionError := SupervisionError#NO_ERROR;
            
            /// Flag: Supervision is active
            _active : BOOL := FALSE;
            
            /// Flag: Expected state has been reached
            _completed : BOOL := FALSE;
            
            /// Previous state of _active for edge detection
            _activePrevious : BOOL := FALSE;
        END_VAR
        
        //=============================================================================
        // PUBLIC METHODS
        //=============================================================================
        
        /// Starts the supervision
        /// Must be called to activate the supervision
        METHOD PUBLIC Start
            _debugStartCounter := _debugStartCounter + UDINT#1;
            
            _active := TRUE;
            _completed := FALSE;
            _error_status := SupervisionError#NO_ERROR;
            _activePrevious := FALSE;
            
            // Reset timer
            _timer(signal := FALSE, duration := timeout);
        END_METHOD
        
        /// Stops the supervision
        METHOD PUBLIC Stop
            _debugStopCounter := _debugStopCounter + UDINT#1;
            
            _active := FALSE;
            _error_status := SupervisionError#NO_ERROR;
            _activePrevious := FALSE;
            
            // Reset timer
            _timer(signal := FALSE, duration := timeout);
        END_METHOD
        
        /// Cyclic execution of the supervision logic
        /// Must be called in every cycle
        /// @param signal: The signal to be monitored
        METHOD PUBLIC Execute
            VAR_INPUT
                signal : BOOL;
            END_VAR
            VAR_TEMP
                expected_state : BOOL;
                condition_met : BOOL;
            END_VAR
            
            _debugExecuteCounter := _debugExecuteCounter + UDINT#1;
            
            // Only monitor when active
            IF NOT _active THEN
                RETURN;
            END_IF;
            
            // If an error already exists or supervision is completed, no further monitoring
            IF (_error_status <> SupervisionError#NO_ERROR) OR _completed THEN
                RETURN;
            END_IF;
            
            // Determine expected state based on behavior
            CASE behavior OF
                SupervisionBehavior#Action:
                    expected_state := TRUE;     // Signal should become TRUE
                SupervisionBehavior#Reaction:
                    expected_state := FALSE;    // Signal should become FALSE
            END_CASE;
            
            // Check if expected state has been reached
            condition_met := (signal = expected_state);
            
            IF condition_met THEN
                // Expected state reached - supervision successful
                _debugCompletedCounter := _debugCompletedCounter + UDINT#1;
                _completed := TRUE;
                _active := FALSE;
                _timer(signal := FALSE, duration := timeout);
                RETURN;
            END_IF;
            
            // Count how often _active is triggered (rising edge detection)
            IF _active AND NOT _activePrevious THEN
                _activeCounter := _activeCounter + UDINT#1;
            END_IF;
            _activePrevious := _active;
            
            // Start/Update timer (runs as long as expected state is NOT reached)
            _timer(signal := _active, duration := timeout);
            
            // Check for timeout
            IF _timer.output THEN
                _debugTimeoutCounter := _debugTimeoutCounter + UDINT#1;
                _error_status := SupervisionError#TIMEOUT;
                _active := FALSE;
            END_IF;
        END_METHOD
        
        /// Returns the current error status
        METHOD PUBLIC GetError : SupervisionError
            GetError := _error_status;
        END_METHOD
        
        /// Checks if an error exists
        METHOD PUBLIC HasError : BOOL
            HasError := (_error_status <> SupervisionError#NO_ERROR);
        END_METHOD
        
        /// Resets the error and stops the supervision
        METHOD PUBLIC Reset
            _error_status := SupervisionError#NO_ERROR;
            THIS.Stop();
        END_METHOD
        
        /// Returns whether the supervision is active
        METHOD PUBLIC IsActive : BOOL
            IsActive := _active;
        END_METHOD
        
        /// Returns whether the supervision has been successfully completed
        METHOD PUBLIC IsCompleted : BOOL
            IsCompleted := _completed;
        END_METHOD
        
    END_CLASS

END_NAMESPACE
