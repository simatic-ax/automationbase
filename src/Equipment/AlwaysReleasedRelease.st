NAMESPACE Simatic.Ax.AutomationBase

    /// Null-Object implementation of IRelease that always returns TRUE
    /// This is used as default when no release strategy is configured
    CLASS INTERNAL AlwaysReleasedRelease IMPLEMENTS IRelease
        METHOD PUBLIC IsReleased : BOOL
            IsReleased := TRUE;
        END_METHOD
    END_CLASS

    /// Simple release implementation that directly exposes a BOOL as release state
    CLASS BoolRelease IMPLEMENTS IRelease
        VAR PUBLIC
            ReleaseSignal : BOOL;
        END_VAR

        METHOD PUBLIC IsReleased : BOOL
            IsReleased := ReleaseSignal;
        END_METHOD
    END_CLASS

END_NAMESPACE
