NAMESPACE Simatic.Ax.AutomationBase.Test

    USING Simatic.Ax.AutomationBase;
    USING Simatic.Ax.IO.Input;
    USING AxUnit.Assert;

    /// Mock equipment for testing reset functionality
    CLASS MockEquipmentForReset EXTENDS EquipmentBase
        VAR PUBLIC
            SimulateError : BOOL;
            ResetWasCalled : BOOL;
            ResetCallCount : INT;
            CustomResetValue : INT;
        END_VAR

        METHOD PROTECTED OVERRIDE InitUser
            ResetWasCalled := FALSE;
            ResetCallCount := 0;
            CustomResetValue := 0;
        END_METHOD

        METHOD PROTECTED OVERRIDE RunCyclicUserCode
            // Simulate error condition
            IF (SimulateError AND NOT THIS.HasError()) THEN
                THIS.SetError(errorState := ErrorState#OtherError,
                             errorText := 'Test error');
            END_IF;
        END_METHOD

        METHOD PROTECTED OVERRIDE ResetFaultUser : BOOL
            // Clear error simulation flag
            SimulateError := FALSE;
            
            // Custom test logic
            ResetWasCalled := TRUE;
            ResetCallCount := ResetCallCount + 1;
            CustomResetValue := 42; // Test value to verify custom reset
            
            ResetFaultUser := TRUE;
        END_METHOD
    END_CLASS

    {TestFixture}
    CLASS ResetCommandIntegrationTest
        VAR PROTECTED
            equipment1, equipment1Stateless : MockEquipmentForReset;
            equipment2, equipment2Stateless : MockEquipmentForReset;
            equipment3, equipment3Stateless : MockEquipmentForReset;
            resetManager, resetManagerStateless : ResetCommandManager;
            modeManager, modeManagerStateless : OperatingModeManager;
            binSignal, binSignalStateless : BinSignal;
        END_VAR

        {TestSetup}
        METHOD PUBLIC Setup
            // Reset to stateless instances
            equipment1 := equipment1Stateless;
            equipment2 := equipment2Stateless;
            equipment3 := equipment3Stateless;
            resetManager := resetManagerStateless;
            modeManager := modeManagerStateless;
            binSignal := binSignalStateless;
            
            // Connect signal to reset manager
            resetManager.ResetSignal := binSignal;
            
            // Configure equipment
            equipment1.Mode := modeManager;
            equipment1.ResetCommand := resetManager;
            
            equipment2.Mode := modeManager;
            equipment2.ResetCommand := resetManager;
            
            equipment3.Mode := modeManager;
            equipment3.ResetCommand := resetManager;
            
            // Initialize equipment
            equipment1.RunCyclic();
            equipment2.RunCyclic();
            equipment3.RunCyclic();
            resetManager.RunCyclic();
        END_METHOD

        {Test}
        METHOD PUBLIC Test_SingleEquipmentWithError_ResetsSuccessfully
            // Arrange: Equipment 1 has error
            equipment1.SimulateError := TRUE;
            equipment1.RunCyclic(); // Sets error in user code
            equipment1.RunCyclic(); // Updates _hasError flag
            resetManager.RunCyclic();
            Equal(actual := equipment1.HasError(), expected := TRUE);
            Equal(actual := resetManager.AnyErrorActive(), expected := TRUE);
            
            // Establish signal state and trigger reset
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            
            equipment1.RunCyclic();
            equipment2.RunCyclic();
            equipment3.RunCyclic();
            resetManager.RunCyclic();
            
            // Assert: Error cleared and custom reset called
            Equal(actual := equipment1.HasError(), expected := FALSE);
            Equal(actual := equipment1.ResetWasCalled, expected := TRUE);
            Equal(actual := equipment1.ResetCallCount, expected := 1);
            Equal(actual := equipment1.CustomResetValue, expected := 42);
            Equal(actual := resetManager.AnyErrorActive(), expected := FALSE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MultipleEquipmentWithErrors_AllReset
            // Arrange: All equipment have errors
            equipment1.SimulateError := TRUE;
            equipment2.SimulateError := TRUE;
            equipment3.SimulateError := TRUE;
            
            equipment1.RunCyclic(); // Sets error
            equipment2.RunCyclic(); // Sets error
            equipment3.RunCyclic(); // Sets error
            equipment1.RunCyclic(); // Updates _hasError flag
            equipment2.RunCyclic(); // Updates _hasError flag
            equipment3.RunCyclic(); // Updates _hasError flag
            resetManager.RunCyclic();
            
            Equal(actual := equipment1.HasError(), expected := TRUE);
            Equal(actual := equipment2.HasError(), expected := TRUE);
            Equal(actual := equipment3.HasError(), expected := TRUE);
            Equal(actual := resetManager.AnyErrorActive(), expected := TRUE);
            
            // Establish signal state and trigger reset
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            
            equipment1.RunCyclic();
            equipment2.RunCyclic();
            equipment3.RunCyclic();
            resetManager.RunCyclic();
            
            // Assert: All errors cleared
            Equal(actual := equipment1.HasError(), expected := FALSE);
            Equal(actual := equipment2.HasError(), expected := FALSE);
            Equal(actual := equipment3.HasError(), expected := FALSE);
            
            Equal(actual := equipment1.ResetWasCalled, expected := TRUE);
            Equal(actual := equipment2.ResetWasCalled, expected := TRUE);
            Equal(actual := equipment3.ResetWasCalled, expected := TRUE);
            
            Equal(actual := resetManager.AnyErrorActive(), expected := FALSE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MixedEquipment_OnlyErrorsReset
            // Arrange: Only equipment 1 and 3 have errors
            equipment1.SimulateError := TRUE;
            equipment3.SimulateError := TRUE;
            
            equipment1.RunCyclic(); // Sets error
            equipment2.RunCyclic();
            equipment3.RunCyclic(); // Sets error
            equipment1.RunCyclic(); // Updates _hasError flag
            equipment3.RunCyclic(); // Updates _hasError flag
            resetManager.RunCyclic();
            
            Equal(actual := resetManager.AnyErrorActive(), expected := TRUE);
            
            // Establish signal state and trigger reset
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            
            equipment1.RunCyclic();
            equipment2.RunCyclic();
            equipment3.RunCyclic();
            resetManager.RunCyclic();
            
            // Assert: Only equipment with errors called reset
            Equal(actual := equipment1.ResetWasCalled, expected := TRUE);
            Equal(actual := equipment2.ResetWasCalled, expected := FALSE); // No error, no reset
            Equal(actual := equipment3.ResetWasCalled, expected := TRUE);
            
            Equal(actual := resetManager.AnyErrorActive(), expected := FALSE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_NoEquipmentWithErrors_NoResets
            // Arrange: No equipment have errors
            equipment1.RunCyclic();
            equipment2.RunCyclic();
            equipment3.RunCyclic();
            resetManager.RunCyclic();
            
            Equal(actual := equipment1.HasError(), expected := FALSE);
            Equal(actual := equipment2.HasError(), expected := FALSE);
            Equal(actual := equipment3.HasError(), expected := FALSE);
            Equal(actual := resetManager.AnyErrorActive(), expected := FALSE);
            
            // Establish signal state and trigger reset
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            
            equipment1.RunCyclic();
            equipment2.RunCyclic();
            equipment3.RunCyclic();
            resetManager.RunCyclic();
            
            // Assert: No resets called
            Equal(actual := equipment1.ResetWasCalled, expected := FALSE);
            Equal(actual := equipment2.ResetWasCalled, expected := FALSE);
            Equal(actual := equipment3.ResetWasCalled, expected := FALSE);
            
            Equal(actual := resetManager.AnyErrorActive(), expected := FALSE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ResetCommand_ClearsAutomatically
            // Arrange: Equipment 1 has error
            equipment1.SimulateError := TRUE;
            equipment1.RunCyclic();
            resetManager.RunCyclic();
            
            // Establish signal state and trigger reset
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            Equal(actual := resetManager.IsResetActive(), expected := TRUE);
            
            // Equipment resets
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            equipment1.RunCyclic();
            equipment2.RunCyclic();
            equipment3.RunCyclic();
            resetManager.RunCyclic();
            
            // Assert: Reset command cleared automatically
            Equal(actual := resetManager.IsResetActive(), expected := FALSE);
            Equal(actual := equipment1.HasError(), expected := FALSE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MultipleResetCycles_WorkCorrectly
            // First reset cycle - establish signal state
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            equipment1.SimulateError := TRUE;
            equipment1.RunCyclic();
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            equipment1.RunCyclic();
            equipment2.RunCyclic();
            equipment3.RunCyclic();
            resetManager.RunCyclic();
            
            Equal(actual := equipment1.HasError(), expected := FALSE);
            Equal(actual := equipment1.ResetCallCount, expected := 1);
            
            // Second reset cycle
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            equipment1.SimulateError := TRUE;
            equipment2.SimulateError := TRUE;
            equipment1.RunCyclic();
            equipment2.RunCyclic();
            equipment3.RunCyclic();
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            equipment1.RunCyclic();
            equipment2.RunCyclic();
            equipment3.RunCyclic();
            resetManager.RunCyclic();
            
            // Assert: Both equipment reset
            Equal(actual := equipment1.HasError(), expected := FALSE);
            Equal(actual := equipment2.HasError(), expected := FALSE);
            Equal(actual := equipment1.ResetCallCount, expected := 2); // Reset twice
            Equal(actual := equipment2.ResetCallCount, expected := 1); // Reset once
        END_METHOD

        {Test}
        METHOD PUBLIC Test_EquipmentWithoutResetCommand_NotAffected
            // Arrange: Disconnect equipment3 from reset manager
            equipment3.ResetCommand := NULL;
            equipment3.SimulateError := TRUE;
            equipment3.RunCyclic();
            resetManager.RunCyclic();
            
            equipment1.SimulateError := TRUE;
            equipment1.RunCyclic();
            resetManager.RunCyclic();
            
            // Establish signal state and trigger reset
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            equipment1.RunCyclic();
            equipment2.RunCyclic();
            equipment3.RunCyclic();
            resetManager.RunCyclic();
            
            // Assert: Only equipment1 reset, equipment3 still has error
            Equal(actual := equipment1.HasError(), expected := FALSE);
            Equal(actual := equipment3.HasError(), expected := TRUE); // Still has error
            Equal(actual := equipment1.ResetWasCalled, expected := TRUE);
            Equal(actual := equipment3.ResetWasCalled, expected := FALSE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ManualResetFault_WorksIndependently
            // Arrange: Equipment has error
            equipment1.SimulateError := TRUE;
            equipment1.RunCyclic(); // Sets error
            equipment1.RunCyclic(); // Updates _hasError flag
            resetManager.RunCyclic();
            Equal(actual := equipment1.HasError(), expected := TRUE);
            
            // Act: Manual reset (not via ResetCommand)
            equipment1.ResetFault();
            
            // Assert: Error cleared and custom reset called
            Equal(actual := equipment1.HasError(), expected := FALSE);
            Equal(actual := equipment1.ResetWasCalled, expected := TRUE);
            Equal(actual := equipment1.CustomResetValue, expected := 42);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ErrorFlag_TracksCorrectly
            // Arrange: Create errors
            equipment1.SimulateError := TRUE;
            equipment2.SimulateError := TRUE;
            
            equipment1.RunCyclic(); // Sets error
            equipment2.RunCyclic(); // Sets error
            equipment3.RunCyclic();
            equipment1.RunCyclic(); // Updates _hasError flag
            equipment2.RunCyclic(); // Updates _hasError flag
            resetManager.RunCyclic();
            
            // Assert: Error flag should be active
            Equal(actual := resetManager.AnyErrorActive(), expected := TRUE);
            
            // Establish signal state and trigger reset
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            equipment1.RunCyclic();
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            equipment2.SimulateError := TRUE; // Keep equipment2 error
            equipment2.RunCyclic();
            equipment3.RunCyclic();
            resetManager.RunCyclic();
            
            // Assert: Error flag still active because equipment2 still has error
            Equal(actual := resetManager.AnyErrorActive(), expected := TRUE);
        END_METHOD
    END_CLASS

END_NAMESPACE
