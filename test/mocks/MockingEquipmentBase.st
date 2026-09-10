USING Simatic.Ax.AutomationBase;
NAMESPACE Simatic.Ax.Conveyor.Mocks

    /// <summary>
    /// Concrete implementation of the abstract EquipmentBase class for testing purposes.
    /// This mock tracks method calls and provides counters for test verification.
    /// </summary>
    CLASS MockEquipmentBase EXTENDS EquipmentBase
        VAR PUBLIC
            /// Flag indicating if RunCyclicUserCode was called at least once
            RunCyclicUserCodeCalled : BOOL;
            /// Flag indicating if InitUser was called at least once
            InitUserCalled : BOOL;
            /// Counter tracking how many times RunCyclicUserCode was called
            RunCyclicUserCodeCallCount : INT;
            /// Counter tracking how many times InitUser was called
            InitUserCallCount : INT;
        END_VAR

        /// <summary>
        /// Override of the abstract RunCyclicUserCode method.
        /// Sets the called flag and increments the call counter for test verification.
        /// </summary>
        METHOD PROTECTED OVERRIDE RunCyclicUserCode
            RunCyclicUserCodeCalled := TRUE;
            RunCyclicUserCodeCallCount := RunCyclicUserCodeCallCount + 1;
        END_METHOD

        /// <summary>
        /// Override of the abstract InitUser method.
        /// Sets the called flag and increments the call counter for test verification.
        /// </summary>
        METHOD PROTECTED OVERRIDE InitUser
            InitUserCalled := TRUE;
            InitUserCallCount := InitUserCallCount + 1;
        END_METHOD

        /// <summary>
        /// Helper method to reset all test tracking flags and counters.
        /// Should be called in test setup to ensure clean state between tests.
        /// </summary>
        METHOD PUBLIC ResetTestFlags
            RunCyclicUserCodeCalled := FALSE;
            InitUserCalled := FALSE;
            RunCyclicUserCodeCallCount := 0;
            InitUserCallCount := 0;
        END_METHOD
    
        METHOD PROTECTED OVERRIDE ResetFaultUser : BOOL
            ResetFaultUser := TRUE;
        END_METHOD
    END_CLASS

END_NAMESPACE
