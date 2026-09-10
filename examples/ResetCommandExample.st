NAMESPACE Simatic.Ax.AutomationBase.Examples

    USING Simatic.Ax.AutomationBase;
    USING Simatic.Ax.IO.Input;

    /// Example demonstrating centralized reset command management
    /// Shows how to use ResetCommandManager with automatic edge detection and IBinSignal
    
    /// Example equipment with custom reset logic
    CLASS ExampleEquipmentWithCustomReset EXTENDS EquipmentBase
        VAR PUBLIC
            Running : BOOL;
            ErrorCondition : BOOL;  // Simulated error condition
            ResetCounter : INT;     // Tracks number of resets
        END_VAR
        
        METHOD PROTECTED OVERRIDE InitUser
            Running := FALSE;
            ResetCounter := 0;
        END_METHOD
        
        METHOD PROTECTED OVERRIDE RunCyclicUserCode
            // Simulate error condition
            IF (ErrorCondition AND NOT THIS.HasError()) THEN
                THIS.SetError(errorState := ErrorState#OtherError,
                             errorText := 'Simulated error');
            END_IF;
            
            // Normal operation when no error
            IF (NOT THIS.HasError()) THEN
                IF (THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp) THEN
                    Running := TRUE;
                ELSE
                    Running := FALSE;
                END_IF;
            ELSE
                Running := FALSE;
            END_IF;
        END_METHOD
        
        /// Custom reset logic - override to add equipment-specific reset behavior
        METHOD PROTECTED OVERRIDE ResetFaultUser
            // Call base implementation to clear error
            SUPER^.ResetFaultUser();
            
            // Add custom reset logic
            ResetCounter := ResetCounter + 1;
            Running := FALSE;
            
            // Clear error condition
            ErrorCondition := FALSE;
            
            // Could add more equipment-specific reset actions:
            // - Reset internal state machines
            // - Clear buffers
            // - Reset actuators to safe position
            // - Log reset event
        END_METHOD
    END_CLASS
    
    /// Example equipment with different custom reset logic
    CLASS ExampleMotorWithReset EXTENDS EquipmentBase
        VAR PUBLIC
            Speed : REAL;
            Position : REAL;
            ErrorCondition : BOOL;
        END_VAR
        
        METHOD PROTECTED OVERRIDE InitUser
            Speed := 0.0;
            Position := 0.0;
        END_METHOD
        
        METHOD PROTECTED OVERRIDE RunCyclicUserCode
            IF (ErrorCondition AND NOT THIS.HasError()) THEN
                THIS.SetError(errorState := ErrorState#OtherError,
                             errorText := 'Motor error');
            END_IF;
            
            IF (NOT THIS.HasError()) THEN
                IF (THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp) THEN
                    Speed := 100.0;
                END_IF;
            ELSE
                Speed := 0.0;
            END_IF;
        END_METHOD
        
        /// Motor-specific reset logic
        METHOD PROTECTED OVERRIDE ResetFaultUser
            // Call base implementation
            SUPER^.ResetFaultUser();
            
            // Motor-specific reset
            Speed := 0.0;
            ErrorCondition := FALSE;
            // Position is NOT reset - we keep position information
        END_METHOD
    END_CLASS
    
    /// Example program showing centralized reset with automatic edge detection
    PROGRAM ResetCommandExample
        VAR
            // Equipment instances
            equipment1 : ExampleEquipmentWithCustomReset;
            equipment2 : ExampleEquipmentWithCustomReset;
            motor1 : ExampleMotorWithReset;
            
            // Shared infrastructure
            modeManager : OperatingModeManager;
            resetManager : ResetCommandManager;  // Central reset manager
            
            // Reset signal (connected to HMI button)
            resetButtonSignal : BinSignal;
            
            // Control inputs
            simulateError1 : BOOL;
            simulateError2 : BOOL;
            simulateError3 : BOOL;
            
            // Monitoring outputs
            hmi_ResetActive : BOOL;
            hmi_AnyError : BOOL;
        END_VAR
        
        // ============================================
        // CONFIGURATION (once during initialization)
        // ============================================
        
        // Configure equipment 1
        equipment1.Mode := modeManager;
        equipment1.ResetCommand := resetManager;  // Connect to central reset
        equipment1.ErrorCondition := simulateError1;
        
        // Configure equipment 2
        equipment2.Mode := modeManager;
        equipment2.ResetCommand := resetManager;  // Same reset manager
        equipment2.ErrorCondition := simulateError2;
        
        // Configure motor
        motor1.Mode := modeManager;
        motor1.ResetCommand := resetManager;  // Same reset manager
        motor1.ErrorCondition := simulateError3;
        
        // Connect reset signal to manager
        resetManager.ResetSignal := resetButtonSignal;
        
        // ============================================
        // SIGNAL INPUT
        // ============================================
        
        // Read reset button signal (connect to your HMI button input)
        resetButtonSignal.ReadCyclic(signal := (* your HMI reset button input *), valid := TRUE);
        
        // ============================================
        // CYCLIC EXECUTION
        // ============================================
        
        // All equipment will automatically:
        // - Report errors via ReportError() when HasError() is TRUE
        // - Check for reset command via GetResetCommand()
        // - Call ResetFaultUser() when reset is active and equipment has error
        equipment1.RunCyclic();
        equipment2.RunCyclic();
        motor1.RunCyclic();
        
        // IMPORTANT: ResetManager must run after all equipment
        // RunCyclic() automatically:
        // - Detects reset signal rising edge via ResetSignal.QRis()
        // - Activates reset command for exactly one cycle
        // - Clears error flag on reset
        resetManager.RunCyclic();
        
        // ============================================
        // MONITORING
        // ============================================
        
        // Check if any equipment has reported errors
        hmi_AnyError := resetManager.AnyErrorActive();
        
        // Check if reset command is currently active
        hmi_ResetActive := resetManager.IsResetActive();
        
        // Example flow:
        // 1. Equipment has error → AnyErrorActive() = TRUE
        // 2. Reset button pressed (rising edge) → IsResetActive() = TRUE for one cycle
        // 3. Equipment resets → AnyErrorActive() = FALSE
        // 4. Next cycle → IsResetActive() = FALSE
    END_PROGRAM

END_NAMESPACE
