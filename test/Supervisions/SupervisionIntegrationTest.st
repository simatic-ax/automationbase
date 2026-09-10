USING AxUnit.Assert;
USING AxUnit.Mocking;
USING Simatic.Ax.AutomationBase;
USING AutomationBase.Tests;

NAMESPACE AutomationBase.Tests

    {TestFixture}
    CLASS SupervisionIntegrationTest
        VAR
            // Stateless copies für jeden Test
            _cylinder_supervision, _cylinder_supervisionStateless : Supervision;
            _motor_supervision, _motor_supervisionStateless : Supervision;
            _two_stage_action, _two_stage_actionStateless : Supervision;
            _two_stage_reaction, _two_stage_reactionStateless : Supervision;
        END_VAR
        
        //=============================================================================
        // SETUP
        //=============================================================================
        
        {TestSetup}
        METHOD PUBLIC TestSetup
            // Kopiere stateless Instanzen für jeden Test
            _cylinder_supervision := _cylinder_supervisionStateless;
            _motor_supervision := _motor_supervisionStateless;
            _two_stage_action := _two_stage_actionStateless;
            _two_stage_reaction := _two_stage_reactionStateless;
        END_METHOD
        
        //=============================================================================
        // INTEGRATIONSTESTS FÜR PNEUMATIKZYLINDER
        //=============================================================================
        
        {Test}
        METHOD PUBLIC Test_PneumaticCylinder_SuccessfulExtension
            VAR_TEMP
                cylinder_extended : BOOL;
                cylinder_retracted : BOOL;
            END_VAR
            
            // Arrange - Zylinder eingefahren
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            cylinder_retracted := TRUE;
            cylinder_extended := FALSE;
            _cylinder_supervision.timeout := T#100ms;
            _cylinder_supervision.behavior := SupervisionBehavior#Action;
            
            // Act - Starte Ausfahren
            _cylinder_supervision.Start();
            
            // Simuliere Zylinderfahrt (nach 5 Zyklen erreicht)
            THIS.SimulateCylinderExtension(
                supervision := _cylinder_supervision,
                cycles_until_extended := 5,
                cylinder_extended := cylinder_extended
            );
            
            // Assert
            Equal(expected := TRUE, actual := _cylinder_supervision.IsCompleted());
            Equal(expected := FALSE, actual := _cylinder_supervision.HasError());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_PneumaticCylinder_BlockedExtension
            VAR_TEMP
                cylinder_extended : BOOL;
            END_VAR
            
            // Arrange - Zylinder blockiert
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_true));
            cylinder_extended := FALSE;
            _cylinder_supervision.timeout := T#10ms;
            _cylinder_supervision.behavior := SupervisionBehavior#Action;
            
            // Act - Starte Ausfahren, aber Zylinder bleibt blockiert
            _cylinder_supervision.Start();
            
            // Zylinder bewegt sich nicht - Timer läuft ab
            _cylinder_supervision.Execute(signal := cylinder_extended);
            
            // Assert
            Equal(expected := TRUE, actual := _cylinder_supervision.HasError());
            EqualSupervisionError(expected := SupervisionError#TIMEOUT, actual := _cylinder_supervision.GetError());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_PneumaticCylinder_RetractAfterExtend
            VAR_TEMP
                cylinder_extended : BOOL;
            END_VAR
            
            // Test: Ausfahren und dann Einfahren
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            
            // Phase 1: Ausfahren
            cylinder_extended := FALSE;
            _cylinder_supervision.timeout := T#100ms;
            _cylinder_supervision.behavior := SupervisionBehavior#Action;
            _cylinder_supervision.Start();
            THIS.SimulateCylinderExtension(
                supervision := _cylinder_supervision,
                cycles_until_extended := 5,
                cylinder_extended := cylinder_extended
            );
            Equal(expected := TRUE, actual := _cylinder_supervision.IsCompleted());
            
            // Phase 2: Einfahren
            _cylinder_supervision.Reset();
            _cylinder_supervision.behavior := SupervisionBehavior#Reaction;
            _cylinder_supervision.Start();
            THIS.SimulateCylinderRetraction(
                supervision := _cylinder_supervision,
                cycles_until_retracted := 5,
                cylinder_extended := cylinder_extended
            );
            Equal(expected := TRUE, actual := _cylinder_supervision.IsCompleted());
        END_METHOD
        
        //=============================================================================
        // INTEGRATIONSTESTS FÜR MOTORSTART
        //=============================================================================
        
        {Test}
        METHOD PUBLIC Test_Motor_SuccessfulStart
            VAR_TEMP
                motor_running : BOOL;
            END_VAR
            
            // Arrange
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            motor_running := FALSE;
            _motor_supervision.timeout := T#50ms;
            _motor_supervision.behavior := SupervisionBehavior#Action;
            
            // Act - Motor starten
            _motor_supervision.Start();
            THIS.SimulateMotorStart(
                supervision := _motor_supervision,
                cycles_until_running := 3,
                motor_running := motor_running
            );
            
            // Assert
            Equal(expected := TRUE, actual := _motor_supervision.IsCompleted());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_Motor_FailedStart
            VAR_TEMP
                motor_running : BOOL;
            END_VAR
            
            // Arrange - Motor startet nicht
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_true));
            motor_running := FALSE;
            _motor_supervision.timeout := T#10ms;
            _motor_supervision.behavior := SupervisionBehavior#Action;
            
            // Act - Versuch Motor zu starten
            _motor_supervision.Start();
            _motor_supervision.Execute(signal := motor_running);
            
            // Assert
            Equal(expected := TRUE, actual := _motor_supervision.HasError());
        END_METHOD
        
        //=============================================================================
        // INTEGRATIONSTESTS FÜR ZWEISTUFIGE ÜBERWACHUNG
        //=============================================================================
        
        {Test}
        METHOD PUBLIC Test_TwoStage_SuccessfulMovement
            VAR_TEMP
                position_left_start : BOOL;
                position_at_target : BOOL;
            END_VAR
            
            // Test: Bewegung mit Aktions- und Reaktionsüberwachung
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            
            // Arrange
            position_left_start := FALSE;
            position_at_target := FALSE;
            _two_stage_action.timeout := T#50ms;
            _two_stage_action.behavior := SupervisionBehavior#Action;
            _two_stage_reaction.timeout := T#100ms;
            _two_stage_reaction.behavior := SupervisionBehavior#Action;
            
            // Act Phase 1: Aktionsüberwachung (Bewegung beginnt)
            _two_stage_action.Start();
            THIS.SimulateMovementStart(
                supervision := _two_stage_action,
                cycles_until_started := 3,
                position_left_start := position_left_start
            );
            Equal(expected := TRUE, actual := _two_stage_action.IsCompleted());
            
            // Act Phase 2: Reaktionsüberwachung (Bewegung endet)
            _two_stage_reaction.Start();
            THIS.SimulateMovementEnd(
                supervision := _two_stage_reaction,
                cycles_until_target := 5,
                position_at_target := position_at_target
            );
            
            // Assert
            Equal(expected := TRUE, actual := _two_stage_reaction.IsCompleted());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_TwoStage_FailsInActionPhase
            VAR_TEMP
                position_left_start : BOOL;
            END_VAR
            
            // Test: Bewegung beginnt nicht
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_true));
            
            // Arrange
            position_left_start := FALSE;
            _two_stage_action.timeout := T#10ms;
            _two_stage_action.behavior := SupervisionBehavior#Action;
            
            // Act - Bewegung beginnt nicht
            _two_stage_action.Start();
            _two_stage_action.Execute(signal := position_left_start);
            
            // Assert
            Equal(expected := TRUE, actual := _two_stage_action.HasError());
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_TwoStage_FailsInReactionPhase
            VAR_TEMP
                position_left_start : BOOL;
                position_at_target : BOOL;
            END_VAR
            
            // Test: Bewegung beginnt, aber erreicht Ziel nicht
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            
            // Arrange
            position_left_start := FALSE;
            position_at_target := FALSE;
            _two_stage_action.timeout := T#50ms;
            _two_stage_action.behavior := SupervisionBehavior#Action;
            _two_stage_reaction.timeout := T#10ms;
            _two_stage_reaction.behavior := SupervisionBehavior#Action;
            
            // Act Phase 1: Bewegung beginnt erfolgreich
            _two_stage_action.Start();
            THIS.SimulateMovementStart(
                supervision := _two_stage_action,
                cycles_until_started := 3,
                position_left_start := position_left_start
            );
            Equal(expected := TRUE, actual := _two_stage_action.IsCompleted());
            
            // Act Phase 2: Ziel wird nicht erreicht
            Mock(NAME_OF(System.Timer.OnDelay), NAME_OF(Simatic.Ax.Mocks.OnDelayMock_true));
            _two_stage_reaction.Start();
            _two_stage_reaction.Execute(signal := position_at_target);
            
            // Assert
            Equal(expected := TRUE, actual := _two_stage_reaction.HasError());
        END_METHOD
        
        //=============================================================================
        // HILFSMETHODEN FÜR SIMULATION
        //=============================================================================
        
        METHOD PRIVATE SimulateCylinderExtension
            VAR_IN_OUT
                supervision : Supervision;
                cylinder_extended : BOOL;
            END_VAR
            VAR_INPUT
                cycles_until_extended : INT;
            END_VAR
            VAR
                i : INT;
            END_VAR
            
            FOR i := 1 TO cycles_until_extended DO
                supervision.Execute(signal := cylinder_extended);
            END_FOR;
            
            // Zylinder erreicht Endposition
            cylinder_extended := TRUE;
            supervision.Execute(signal := cylinder_extended);
        END_METHOD
        
        METHOD PRIVATE SimulateCylinderRetraction
            VAR_IN_OUT
                supervision : Supervision;
                cylinder_extended : BOOL;
            END_VAR
            VAR_INPUT
                cycles_until_retracted : INT;
            END_VAR
            VAR
                i : INT;
            END_VAR
            
            FOR i := 1 TO cycles_until_retracted DO
                supervision.Execute(signal := cylinder_extended);
            END_FOR;
            
            // Zylinder erreicht Endposition
            cylinder_extended := FALSE;
            supervision.Execute(signal := cylinder_extended);
        END_METHOD
        
        METHOD PRIVATE SimulateMotorStart
            VAR_IN_OUT
                supervision : Supervision;
                motor_running : BOOL;
            END_VAR
            VAR_INPUT
                cycles_until_running : INT;
            END_VAR
            VAR
                i : INT;
            END_VAR
            
            FOR i := 1 TO cycles_until_running DO
                supervision.Execute(signal := motor_running);
            END_FOR;
            
            // Motor läuft
            motor_running := TRUE;
            supervision.Execute(signal := motor_running);
        END_METHOD
        
        METHOD PRIVATE SimulateMovementStart
            VAR_IN_OUT
                supervision : Supervision;
                position_left_start : BOOL;
            END_VAR
            VAR_INPUT
                cycles_until_started : INT;
            END_VAR
            VAR
                i : INT;
            END_VAR
            
            FOR i := 1 TO cycles_until_started DO
                supervision.Execute(signal := position_left_start);
            END_FOR;
            
            // Startposition verlassen
            position_left_start := TRUE;
            supervision.Execute(signal := position_left_start);
        END_METHOD
        
        METHOD PRIVATE SimulateMovementEnd
            VAR_IN_OUT
                supervision : Supervision;
                position_at_target : BOOL;
            END_VAR
            VAR_INPUT
                cycles_until_target : INT;
            END_VAR
            VAR
                i : INT;
            END_VAR
            
            FOR i := 1 TO cycles_until_target DO
                supervision.Execute(signal := position_at_target);
            END_FOR;
            
            // Zielposition erreicht
            position_at_target := TRUE;
            supervision.Execute(signal := position_at_target);
        END_METHOD
        
    END_CLASS

END_NAMESPACE
