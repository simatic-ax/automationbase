USING Simatic.Ax.AutomationBase;
NAMESPACE Simatic.Ax.Conveyor.Mocks

    CLASS MockIsReleased_TRUE
        IMPLEMENTS IRelease
        METHOD PUBLIC IsReleased : BOOL
            IsReleased := TRUE;
        END_METHOD
    END_CLASS
    CLASS MockIsReleased_FALSE
        IMPLEMENTS IRelease
        METHOD PUBLIC IsReleased : BOOL
            IsReleased := FALSE;
        END_METHOD
    END_CLASS

END_NAMESPACE
