USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.AutomationBase.Tests.ApplicationExample_01

    CLASS MyConveyor EXTENDS EquipmentBase
        VAR PUBLIC
            Speed : LREAL;
            Running : BOOL;
        END_VAR

        METHOD PROTECTED OVERRIDE InitUser
            Speed := 0.0;
            Running := FALSE;
        END_METHOD

        METHOD PROTECTED OVERRIDE RunCyclicUserCode
            IF (THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp) THEN
                Running := TRUE;

                IF (Mode.GetOperatingMode() = OperatingModes#Automatic) THEN
                    Speed := 100.0;
                ELSE
                    Speed := 0.0;
                END_IF;
            ELSE
                Running := FALSE;
                Speed := 0.0;
            END_IF;
        END_METHOD

        METHOD PROTECTED OVERRIDE ResetFaultUser : BOOL
            ResetFaultUser := TRUE;
        END_METHOD
    END_CLASS

END_NAMESPACE