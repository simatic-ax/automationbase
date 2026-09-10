NAMESPACE Simatic.Ax.Mocks
    /// Mock für OnDelay Timer - verhält sich wie echter Timer
    /// Gibt TRUE zurück wenn signal TRUE ist
    FUNCTION_BLOCK OnDelayMock_passthrough
        VAR_INPUT
            duration : LTIME;
            signal : BOOL;
        END_VAR
        VAR_OUTPUT
            output : BOOL;
            elapsedTime : LTIME;
        END_VAR
        output := signal;
    END_FUNCTION_BLOCK
END_NAMESPACE
