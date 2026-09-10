NAMESPACE Simatic.Ax.AutomationBase

    {axcode:docs-v0:@simatic-ax/automationbase:EquipmentBase.md}
    /// Abstract base class for all equipment
    /// Provides initialization, cyclic execution, error handling, and automatic startup
    /// Inherit from this class and implement InitUser() and RunCyclicUserCode()
    CLASS ABSTRACT EquipmentBase
        IMPLEMENTS IEquipmentBase
        VAR PUBLIC
            /// Duration of startup warning phase before equipment is fully started (default: 5 seconds)
            StartUpTime : TIME := T#5s;
            
            /// Operating mode provider (MANDATORY - must be assigned)
            Mode : IOperatingMode;
            
            /// External release provider (optional - if NULL, equipment is always released)
            ExternalRelease : IRelease;
            
            /// Custom auto-startup implementation (optional - if NULL, uses internal default)
            ExternalAutoStartup : IAutoStartup;
            
            /// Reset command provider (optional - if NULL, no automatic reset)
            ResetCommand : IResetCommand;
        END_VAR
        VAR PRIVATE
            /// Flag indicating if equipment has been initialized
            isInitialized : BOOL;
            
            /// Internal default auto-startup implementation
            _defaultAutoStartup : EquipmentAutoStartup;
            
            /// Active auto-startup instance (either external or default)
            _autoRelease : IAutoStartup;
            
            /// Flag indicating if default auto-startup is being used
            _useDefaultAutoStartup : BOOL;

            /// stores the current startup status of the equipment
            _startupStatus : StartUpStatus;
        END_VAR
        VAR PROTECTED
            /// Equipment has any error
            _hasError : BOOL;

            /// Current error state
            _errorState : WORD;
            
            /// Last error message
            _errorText : STRING[30];
        END_VAR

        /// Main cyclic method - call this every PLC cycle
        /// Handles automatic initialization on first call
        METHOD PUBLIC RunCyclic
            VAR_TEMP
                noConfigError : BOOL;
                resetCommandActive : BOOL;
            END_VAR
            IF NOT (isInitialized) THEN
                THIS.Init();
            END_IF;
            
            noConfigError := _errorState <> ErrorState#ConfigError;
            _hasError := _errorState <> ErrorState#NoError;
            IF (noConfigError) THEN
                // Only run default auto startup if no external auto startup is provided
                IF (_useDefaultAutoStartup) THEN
                    _defaultAutoStartup.RunCyclic();
                END_IF;
                THIS.RunCyclicUserCode();
            END_IF;
            
            // Handle automatic reset command if configured
            IF (ResetCommand <> NULL) THEN
                resetCommandActive := ResetCommand.ResetFaultRequest();
                IF (resetCommandActive AND _hasError) THEN
                    THIS.ResetFault();
                END_IF;
    
            // Report error status to reset manager if configured
            IF (ResetCommand <> NULL AND _hasError) THEN
                ResetCommand.ReportError();
            END_IF;

            END_IF;
            
        END_METHOD

        /// Private initialization method - called automatically on first RunCyclic()
        /// Configures auto-startup and validates configuration
        METHOD PRIVATE Init
            IF (ExternalAutoStartup <> NULL) THEN
                _autoRelease := ExternalAutoStartup;
                _useDefaultAutoStartup := FALSE;
            ELSE
                _defaultAutoStartup.StartUpTime := StartUpTime;
                _defaultAutoStartup.Release := ExternalRelease;
                _defaultAutoStartup.Mode := Mode;
                _defaultAutoStartup.Equipment := THIS;
                _autoRelease := _defaultAutoStartup;  // set auto release to default behavior
                _useDefaultAutoStartup := TRUE;
            END_IF;
            IF (Mode = NULL) THEN
                THIS.SetError(errorState := ErrorState#ConfigError);
            END_IF;

            THIS.InitUser();
            isInitialized := TRUE;
        END_METHOD
        /// Abstract method for cyclic user code
        /// Implement this in derived classes for equipment-specific logic
        METHOD PROTECTED ABSTRACT RunCyclicUserCode
        END_METHOD
        
        /// Abstract method for user initialization
        /// Implement this in derived classes for equipment-specific initialization
        METHOD PROTECTED ABSTRACT InitUser
        END_METHOD

        /// Returns TRUE if equipment has an error
        METHOD PUBLIC HasError : BOOL
            HasError := _hasError;
        END_METHOD

        /// Returns the current startup status
        METHOD PUBLIC GetStartupStatus : StartUpStatus
            IF _autoRelease = NULL THEN
                GetStartupStatus := StartUpStatus#InternalError;
                RETURN;
            END_IF;
            _startupStatus := _autoRelease.Status();
            GetStartupStatus := _startupStatus;
        END_METHOD

        /// Returns the current error code
        METHOD PUBLIC GetError : WORD
            GetError := _errorState;
        END_METHOD

        /// Sets an error state
        METHOD PUBLIC SetError
            VAR_INPUT
                errorState : WORD;
            END_VAR
            _errorState := errorState;
            _errorText := '';
        END_METHOD
        
        /// Sets an error state with error text
        METHOD PUBLIC SetError
            VAR_INPUT
                errorState : WORD;
                errorText : STRING[30];
            END_VAR
            _errorState := errorState;
            _errorText := errorText;
            IF (errorState <> ErrorState#NoError) THEN
                _hasError := TRUE;
            END_IF;
        END_METHOD
        
        /// Returns the last error message
        METHOD PUBLIC GetErrorText : STRING[30]
            GetErrorText := _errorText;
        END_METHOD
        
        /// Resets the fault state and clears error message
        METHOD PUBLIC ResetFault
            IF (THIS.ResetFaultUser()) THEN
                _errorState := ErrorState#NoError;
                _errorText := '';
                _hasError := FALSE;
            END_IF;
        END_METHOD
        
        /// User-specific reset logic (can be overridden in derived classes)
        /// Default implementation clears error state and text
        METHOD ABSTRACT ResetFaultUser : BOOL
        END_METHOD
    END_CLASS

END_NAMESPACE

