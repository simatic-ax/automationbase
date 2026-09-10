USING Simatic.Ax.IO.Input;

NAMESPACE Simatic.Ax.AutomationBase

    /// Release implementation that evaluates an IBinSignal
    CLASS BinSignalRelease IMPLEMENTS IRelease
        VAR PUBLIC
            ReleaseSignal : IBinSignal;
        END_VAR

        METHOD PUBLIC IsReleased : BOOL
            IF (ReleaseSignal = NULL) THEN
                IsReleased := FALSE;
                RETURN;
            END_IF;

            IsReleased := ReleaseSignal.Q();
        END_METHOD
    END_CLASS

END_NAMESPACE