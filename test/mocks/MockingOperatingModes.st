USING Simatic.Ax.AutomationBase;
NAMESPACE Simatic.Ax.Conveyor.Mocks

    CLASS MockOperatingMode
        IMPLEMENTS IOperatingMode
        VAR PUBLIC
            mode : OperatingModes;
        END_VAR
        METHOD PUBLIC GetOperatingMode : OperatingModes
            GetOperatingMode := mode;
        END_METHOD
    END_CLASS
END_NAMESPACE
