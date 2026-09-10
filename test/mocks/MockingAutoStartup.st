USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.Conveyor.Mocks

    /// <summary>
    /// Mock implementation of IAutoStartup interface for testing.
    /// Allows tests to control the startup status returned by the Status() method.
    /// </summary>
    CLASS MockAutoStartup
        IMPLEMENTS IAutoStartup
        VAR PUBLIC
            /// Configurable startup status that will be returned by Status() method
            startupStatus : StartUpStatus := StartUpStatus#NotReleased;
        END_VAR

        /// <summary>
        /// Returns the configured startup status.
        /// </summary>
        /// <returns>The current value of startupStatus</returns>
        METHOD PUBLIC Status : StartUpStatus
            Status := startupStatus;
        END_METHOD
    END_CLASS

END_NAMESPACE
