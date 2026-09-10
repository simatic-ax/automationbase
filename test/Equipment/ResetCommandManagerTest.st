NAMESPACE Simatic.Ax.AutomationBase.Test

    USING Simatic.Ax.AutomationBase;
    USING Simatic.Ax.IO.Input;
    USING AxUnit.Assert;

    {TestFixture}
    CLASS ResetCommandManagerTest
        VAR PROTECTED
            resetManager, resetManagerStateless : ResetCommandManager;
            binSignal, binSignalStateless : BinSignal;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            // Reset to stateless instances for clean state
            resetManager := resetManagerStateless;
            binSignal := binSignalStateless;
            
            // Connect signal to reset manager
            resetManager.ResetSignal := binSignal;
            
            // Establish initial signal state (LOW)
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
        END_METHOD

        {Test}
        METHOD PUBLIC Test_InitialState_NoErrorsActive
            // Assert: Initial state should have no errors
            Equal(actual := resetManager.AnyErrorActive(), expected := FALSE);
            Equal(actual := resetManager.AnyErrorActive(), expected := FALSE);
            Equal(actual := resetManager.IsResetActive(), expected := FALSE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ReportError_SetsErrorActive
            // Act: Report an error and complete cycle
            resetManager.ReportError();
            resetManager.RunCyclic();
            
            // Assert: Error should be active
            Equal(actual := resetManager.AnyErrorActive(), expected := TRUE);
            Equal(actual := resetManager.AnyErrorActive(), expected := TRUE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MultipleReportError_SetsErrorActive
            // Act: Report multiple errors and complete cycle
            resetManager.ReportError();
            resetManager.ReportError();
            resetManager.ReportError();
            resetManager.RunCyclic();
            
            // Assert: Error should be active
            Equal(actual := resetManager.AnyErrorActive(), expected := TRUE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ResetSignal_ClearsErrorFlag
            // Arrange: Report an error and complete cycle
            resetManager.ReportError();
            resetManager.RunCyclic();
            Equal(actual := resetManager.AnyErrorActive(), expected := TRUE);
            
            // Establish signal state and trigger reset
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            
            // Acknowledge reset and run cycle
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            // Assert: Reset should be cleared
            Equal(actual := resetManager.IsResetActive(), expected := FALSE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ResetSignal_ActivatesResetCommand
            // Arrange: Establish initial signal state
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            // Act: Trigger reset via signal (rising edge)
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            
            // Assert: Reset command should be active
            Equal(actual := resetManager.ResetFaultRequest(), expected := TRUE);
            Equal(actual := resetManager.IsResetActive(), expected := TRUE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ResetCommand_ClearsWhenNoErrors
            // Arrange: Establish initial signal state, then trigger reset with no errors
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            Equal(actual := resetManager.IsResetActive(), expected := TRUE);
            
            // Act: Run another cycle with no errors (no acknowledgments needed)
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            // Assert: Reset command should clear (0 errors at reset, 0 acknowledgments = cleared)
            Equal(actual := resetManager.IsResetActive(), expected := FALSE);
            Equal(actual := resetManager.ResetFaultRequest(), expected := FALSE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ResetCommand_ActiveForOneCycleOnly
            // Arrange: Establish signal state, report error, complete cycle, then trigger reset
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            resetManager.ReportError();
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            Equal(actual := resetManager.IsResetActive(), expected := TRUE);
            
            // Act: Run cyclic - reset should be cleared after one cycle
            resetManager.ReportError();
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            // Assert: Reset command cleared after one cycle, but error still active
            Equal(actual := resetManager.IsResetActive(), expected := FALSE);
            Equal(actual := resetManager.ResetFaultRequest(), expected := FALSE);
            Equal(actual := resetManager.AnyErrorActive(), expected := TRUE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ResetSignal_ClearsErrorFlagAndResetCommand
            // Arrange: Report error and complete cycle
            resetManager.ReportError();
            resetManager.RunCyclic();
            Equal(actual := resetManager.AnyErrorActive(), expected := TRUE);
            
            // Establish signal state and trigger reset
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            Equal(actual := resetManager.IsResetActive(), expected := TRUE);
            
            // Run cyclic again
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            // Assert: Reset and error flag should be cleared
            Equal(actual := resetManager.IsResetActive(), expected := FALSE);
            Equal(actual := resetManager.AnyErrorActive(), expected := FALSE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_EdgeDetection_OnlyTriggersOnRisingEdge
            VAR_TEMP
                firstCheck : BOOL;
                secondCheck : BOOL;
            END_VAR
            
            // Arrange: Establish initial signal state
            binSignal.ReadCyclic(signal := FALSE, valid := TRUE);
            resetManager.RunCyclic();
            
            // Act: Trigger reset (rising edge)
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            firstCheck := resetManager.IsResetActive();
            
            // Hold signal high (no rising edge)
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            
            // Clear reset by having no errors
            binSignal.ReadCyclic(signal := TRUE, valid := TRUE);
            resetManager.RunCyclic();
            secondCheck := resetManager.IsResetActive();
            
            // Assert: First trigger activates, second doesn't re-trigger
            Equal(actual := firstCheck, expected := TRUE);
            Equal(actual := secondCheck, expected := FALSE);
        END_METHOD
    END_CLASS

END_NAMESPACE
