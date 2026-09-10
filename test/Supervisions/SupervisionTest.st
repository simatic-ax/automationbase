USING AxUnit.Assert;
USING AxUnit.Mocking;
USING Simatic.Ax.AutomationBase;
USING AutomationBase.Tests;

NAMESPACE AutomationBase.Tests

    {TestFixture}
    CLASS SupervisionTest
        VAR
            // Stateless copies für jeden Test
            _supervision, _supervisionStateless : Supervision;
        END_VAR
        
        //=============================================================================
        // SETUP
        //=============================================================================
        
        {TestSetup}
        METHOD PUBLIC TestSetup
            // Kopiere stateless Instanz für jeden Test
            _supervision := _supervisionStateless;
            
            // Konfiguration
            _supervision.timeout := T#100ms;
            _supervision.behavior := SupervisionBehavior#Action;
        END_METHOD
        
        //=============================================================================
        // TESTS FÜR ACTION-VERHALTEN (Signal muss TRUE werden)
        //=============================================================================
        
        {Test}
        METHOD PUBLIC Test_Action_SignalBecomesTrue_CompletesSuccessfully
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Arrange
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            _supervision.behavior := SupervisionBehavior#Action;
            _supervision.Start();
            
            // Act - Signal wird TRUE
            testSignal := TRUE;
            _supervision.Execute(signal := testSignal);
            
            // Assert
            Equal(expected := TRUE, actual := _supervision.IsCompleted());
            Equal(expected := FALSE, actual := _supervision.HasError());
            Equal(expected := FALSE, actual := _supervision.IsActive());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_Action_SignalStaysFalse_CausesTimeout
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Arrange
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_true));
            _supervision.behavior := SupervisionBehavior#Action;
            _supervision.Start();
            
            // Act - Signal bleibt FALSE, Timer gibt TRUE zurück (Timeout)
            testSignal := FALSE;
            _supervision.Execute(signal := testSignal);
            
            // Assert
            Equal(expected := TRUE, actual := _supervision.HasError());
            EqualSupervisionError(expected := SupervisionError#TIMEOUT, actual := _supervision.GetError());
            Equal(expected := FALSE, actual := _supervision.IsActive());
            Equal(expected := FALSE, actual := _supervision.IsCompleted());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_Action_SignalBecomesTrueBeforeTimeout_NoError
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Arrange
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            _supervision.behavior := SupervisionBehavior#Action;
            _supervision.Start();
            
            // Act - Signal wird TRUE vor Timeout
            testSignal := FALSE;
            _supervision.Execute(signal := testSignal);
            testSignal := TRUE;
            _supervision.Execute(signal := testSignal);
            
            // Assert
            Equal(expected := FALSE, actual := _supervision.HasError());
            Equal(expected := TRUE, actual := _supervision.IsCompleted());
        END_METHOD
        
        //=============================================================================
        // TESTS FÜR REACTION-VERHALTEN (Signal muss FALSE werden)
        //=============================================================================
        
        {Test}
        METHOD PUBLIC Test_Reaction_SignalBecomesFalse_CompletesSuccessfully
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Arrange
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            _supervision.behavior := SupervisionBehavior#Reaction;
            _supervision.Start();
            
            // Act - Signal wird FALSE
            testSignal := FALSE;
            _supervision.Execute(signal := testSignal);
            
            // Assert
            Equal(expected := TRUE, actual := _supervision.IsCompleted());
            Equal(expected := FALSE, actual := _supervision.HasError());
            Equal(expected := FALSE, actual := _supervision.IsActive());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_Reaction_SignalStaysTrue_CausesTimeout
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Arrange
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_true));
            _supervision.behavior := SupervisionBehavior#Reaction;
            _supervision.Start();
            
            // Act - Signal bleibt TRUE, Timer gibt TRUE zurück (Timeout)
            testSignal := TRUE;
            _supervision.Execute(signal := testSignal);
            
            // Assert
            Equal(expected := TRUE, actual := _supervision.HasError());
            EqualSupervisionError(expected := SupervisionError#TIMEOUT, actual := _supervision.GetError());
            Equal(expected := FALSE, actual := _supervision.IsActive());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_Reaction_SignalBecomesFalseBeforeTimeout_NoError
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Arrange
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            _supervision.behavior := SupervisionBehavior#Reaction;
            _supervision.Start();
            
            // Act - Signal wird FALSE vor Timeout
            testSignal := TRUE;
            _supervision.Execute(signal := testSignal);
            testSignal := FALSE;
            _supervision.Execute(signal := testSignal);
            
            // Assert
            Equal(expected := FALSE, actual := _supervision.HasError());
            Equal(expected := TRUE, actual := _supervision.IsCompleted());
        END_METHOD
        
        //=============================================================================
        // TESTS FÜR START/STOP/RESET
        //=============================================================================
        
        {Test}
        METHOD PUBLIC Test_Start_ActivatesSupervision
            // Act
            _supervision.Start();
            
            // Assert
            Equal(expected := TRUE, actual := _supervision.IsActive());
            Equal(expected := FALSE, actual := _supervision.IsCompleted());
            Equal(expected := FALSE, actual := _supervision.HasError());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_Stop_DeactivatesSupervision
            // Arrange
            _supervision.Start();
            
            // Act
            _supervision.Stop();
            
            // Assert
            Equal(expected := FALSE, actual := _supervision.IsActive());
            Equal(expected := FALSE, actual := _supervision.HasError());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_Reset_ClearsErrorAndStops
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Arrange
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_true));
            _supervision.Start();
            testSignal := FALSE;
            _supervision.Execute(signal := testSignal);
            Equal(expected := TRUE, actual := _supervision.HasError());
            
            // Act
            _supervision.Reset();
            
            // Assert
            Equal(expected := FALSE, actual := _supervision.HasError());
            Equal(expected := FALSE, actual := _supervision.IsActive());
            EqualSupervisionError(expected := SupervisionError#NO_ERROR, actual := _supervision.GetError());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_MultipleStarts_ResetsState
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Arrange
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            _supervision.Start();
            testSignal := TRUE;
            _supervision.Execute(signal := testSignal);
            Equal(expected := TRUE, actual := _supervision.IsCompleted());
            
            // Act - Erneuter Start
            _supervision.Start();
            
            // Assert
            Equal(expected := TRUE, actual := _supervision.IsActive());
            Equal(expected := FALSE, actual := _supervision.IsCompleted());
            Equal(expected := FALSE, actual := _supervision.HasError());
        END_METHOD
        
        //=============================================================================
        // TESTS FÜR EDGE CASES
        //=============================================================================
        
        {Test}
        METHOD PUBLIC Test_ExecuteWithoutStart_DoesNothing
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Act - Execute ohne Start
            testSignal := TRUE;
            _supervision.Execute(signal := testSignal);
            
            // Assert
            Equal(expected := FALSE, actual := _supervision.IsActive());
            Equal(expected := FALSE, actual := _supervision.IsCompleted());
            Equal(expected := FALSE, actual := _supervision.HasError());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_ExecuteAfterCompletion_DoesNotChangeState
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Arrange
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            _supervision.Start();
            testSignal := TRUE;
            _supervision.Execute(signal := testSignal);
            Equal(expected := TRUE, actual := _supervision.IsCompleted());
            
            // Act - Weitere Execute-Aufrufe
            testSignal := FALSE;
            _supervision.Execute(signal := testSignal);
            
            // Assert - Zustand bleibt unverändert
            Equal(expected := TRUE, actual := _supervision.IsCompleted());
            Equal(expected := FALSE, actual := _supervision.HasError());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_ExecuteAfterError_DoesNotChangeState
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Arrange - Erzeuge Timeout
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_true));
            _supervision.Start();
            testSignal := FALSE;
            _supervision.Execute(signal := testSignal);
            Equal(expected := TRUE, actual := _supervision.HasError());
            
            // Act - Weitere Execute-Aufrufe
            testSignal := TRUE;
            _supervision.Execute(signal := testSignal);
            
            // Assert - Fehler bleibt bestehen
            Equal(expected := TRUE, actual := _supervision.HasError());
            Equal(expected := FALSE, actual := _supervision.IsCompleted());
        END_METHOD
        
        //=============================================================================
        // TESTS FÜR ZUSTANDSÜBERGÄNGE
        //=============================================================================
        
        {Test}
        METHOD PUBLIC Test_StateTransition_NotStarted_To_Active
            // Initial
            Equal(expected := FALSE, actual := _supervision.IsActive());
            
            // Start
            _supervision.Start();
            Equal(expected := TRUE, actual := _supervision.IsActive());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_StateTransition_Active_To_Completed
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Arrange
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            
            // Start
            _supervision.Start();
            Equal(expected := TRUE, actual := _supervision.IsActive());
            
            // Complete
            testSignal := TRUE;
            _supervision.Execute(signal := testSignal);
            Equal(expected := FALSE, actual := _supervision.IsActive());
            Equal(expected := TRUE, actual := _supervision.IsCompleted());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_StateTransition_Active_To_Error
            VAR_TEMP
                testSignal : BOOL;
            END_VAR
            
            // Arrange
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_true));
            
            // Start
            _supervision.Start();
            Equal(expected := TRUE, actual := _supervision.IsActive());
            
            // Timeout
            testSignal := FALSE;
            _supervision.Execute(signal := testSignal);
            Equal(expected := FALSE, actual := _supervision.IsActive());
            Equal(expected := TRUE, actual := _supervision.HasError());
        END_METHOD
        
    END_CLASS

END_NAMESPACE
