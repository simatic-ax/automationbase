
NAMESPACE Simatic.Ax.AutomationBase

    CLASS MockAutoReleaseIsReleased
        IMPLEMENTS IRelease

        METHOD PUBLIC IsReleased : BOOL
            IsReleased := TRUE;;
        END_METHOD
    END_CLASS
END_NAMESPACE
