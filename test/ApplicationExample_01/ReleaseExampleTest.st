USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.AutomationBase.Tests.ApplicationExample_01

    {TestFixture}
    CLASS ReleaseExampleTest
        VAR
            conveyor : MyConveyor;
            conveyorStateless : MyConveyor := (ExternalRelease := releaseByBool, StartUpTime := T#0s, Mode := modeProvider);
            modeProvider, modeProviderStateless : OperatingModeManager;
            releaseByBool, releaseByBoolStateless : BoolRelease;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            conveyor := conveyorStateless;
            modeProvider := modeProviderStateless;
            releaseByBool := releaseByBoolStateless;

            modeProvider.SetOperatingMode(mode := OperatingModes#Automatic);
        END_METHOD

        {Test}
        METHOD PUBLIC BoolRelease_WithFalseSignal_ReturnsFalse
            // Arrange
            releaseByBool.ReleaseSignal := FALSE;

            // Act
            // Assert
            Equal(expected := FALSE, actual := releaseByBool.IsReleased());
        END_METHOD

        {Test}
        METHOD PUBLIC BoolRelease_WithTrueSignal_ReturnsTrue
            // Arrange
            releaseByBool.ReleaseSignal := TRUE;

            // Act
            // Assert
            Equal(expected := TRUE, actual := releaseByBool.IsReleased());
        END_METHOD

        {Test}
        METHOD PUBLIC RunCyclic_WithFalseRelease_KeepsConveyorStopped
            // Arrange
            releaseByBool.ReleaseSignal := TRUE;
            conveyor.RunCyclic();
            releaseByBool.ReleaseSignal := FALSE;

            // Act
            conveyor.RunCyclic();

            // Assert
            Equal(expected := FALSE, actual := conveyor.Running);
            Equal(expected := 0.0, actual := conveyor.Speed);
            Equal(expected := TRUE, actual := conveyor.GetStartupStatus() = StartUpStatus#NotReleased);
        END_METHOD

        {Test}
        METHOD PUBLIC RunCyclic_WithTrueRelease_StartsConveyorInAutomatic
            // Arrange
            releaseByBool.ReleaseSignal := TRUE;

            // Act
            conveyor.RunCyclic();

            // Assert
            Equal(expected := TRUE, actual := conveyor.Running);
            Equal(expected := 100.0, actual := conveyor.Speed);
            Equal(expected := TRUE, actual := conveyor.GetStartupStatus() = StartUpStatus#AutoStartedUp);
        END_METHOD
    END_CLASS

END_NAMESPACE