USING Simatic.Ax.Conveyor.Mocks;
USING AxUnit.Assert;
USING AutomationBase.Tests;

NAMESPACE Simatic.Ax.AutomationBase

    /// <summary>
    /// Comprehensive test suite for the EquipmentBase abstract class.
    /// Tests initialization, cyclic execution, error handling, startup status,
    /// and various configuration scenarios.
    /// </summary>
    {TestFixture}
    CLASS EquipmentBaseTest
        VAR
            // Test equipment instance and stateless backup for reset between tests
            equipment, equipmentStateless : MockEquipmentBase;
            // Mock operating mode and stateless backup
            mockMode, mockModeStateless : MockOperatingMode;
            // Mock release that always returns TRUE
            releaseTrue : MockIsReleased_TRUE;
            // Mock release that always returns FALSE
            releaseFalse : MockIsReleased_FALSE;
            // Mock auto startup and stateless backup
            mockAutoStartup, mockAutoStartupStateless : MockAutoStartup;
        END_VAR
        
        /// <summary>
        /// Setup method executed before each test.
        /// Resets all test instances to stateless state and clears tracking flags.
        /// </summary>
        {TestSetup}
        METHOD PUBLIC TestSetup
            // Reset to stateless instances for clean state
            equipment := equipmentStateless;
            mockMode := mockModeStateless;
            mockAutoStartup := mockAutoStartupStateless;
            // Clear all test tracking flags
            equipment.ResetTestFlags();
        END_METHOD

        // ========================================
        // Initialization Tests
        // ========================================

        /// <summary>
        /// Test: Verifies that Init() calls the abstract InitUser() method.
        /// This ensures derived classes can perform custom initialization.
        /// </summary>
        {Test}
        METHOD PUBLIC Init_Calls_InitUser
            // Arrange: Setup valid configuration
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            
            // Act: Initialize equipment via RunCyclic (Init is private)
            equipment.RunCyclic();
            
            // Assert: InitUser should have been called
            Equal(expected := TRUE, actual := equipment.InitUserCalled);
        END_METHOD

        /// <summary>
        /// Test: Verifies that initialization only happens once.
        /// Subsequent calls to RunCyclic should not trigger Init again.
        /// </summary>
        {Test}
        METHOD PUBLIC Init_Sets_IsInitialized_Flag
            // Arrange: Setup valid configuration
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            
            // Act: Initialize equipment
            equipment.RunCyclic();
            
            // Verify by calling RunCyclic - should not call Init again
            equipment.ResetTestFlags();
            equipment.RunCyclic();
            
            // Assert: InitUser should NOT be called again
            Equal(expected := FALSE, actual := equipment.InitUserCalled);
        END_METHOD

        /// <summary>
        /// Test: Verifies that missing Mode configuration sets ConfigError.
        /// Equipment requires a valid operating mode to function.
        /// </summary>
        {Test}
        METHOD PUBLIC Init_Without_Mode_Sets_ConfigError
            // Arrange: Set Mode to NULL (invalid configuration)
            equipment.Mode := NULL;
            
            // Act: Attempt to initialize via RunCyclic (Init is private)
            equipment.RunCyclic();
            
            // Assert: Should have error state
            Equal(expected := TRUE, actual := equipment.HasError());
        END_METHOD

        /// <summary>
        /// Test: Verifies that external auto startup is used when provided.
        /// This allows custom startup behavior to override the default.
        /// </summary>
        {Test}
        METHOD PUBLIC Init_With_ExternalAutoStartup_Uses_External
            // Arrange: Setup with external auto startup
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            mockAutoStartup.startupStatus := StartUpStatus#NotReleased;
            equipment.ExternalAutoStartup := mockAutoStartup;
            
            // Act: Initialize equipment via RunCyclic (Init is private)
            equipment.RunCyclic();
            
            // Assert: Should initialize successfully with external startup
            Equal(expected := TRUE, actual := equipment.InitUserCalled);
        END_METHOD

        /// <summary>
        /// Test: Verifies that default auto startup is used when external is NULL.
        /// This is the standard behavior for most equipment.
        /// </summary>
        {Test}
        METHOD PUBLIC Init_Without_ExternalAutoStartup_Uses_Default
            // Arrange: Setup without external auto startup
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            equipment.ExternalAutoStartup := NULL;
            equipment.ExternalRelease := releaseTrue;
            
            // Act: Initialize equipment via RunCyclic (Init is private)
            equipment.RunCyclic();
            
            // Assert: Should initialize successfully with default startup
            Equal(expected := TRUE, actual := equipment.InitUserCalled);
        END_METHOD

        // ========================================
        // RunCyclic Tests
        // ========================================

        /// <summary>
        /// Test: Verifies that RunCyclic automatically calls Init on first execution.
        /// This ensures equipment is always initialized before running user code.
        /// </summary>
        {Test}
        METHOD PUBLIC RunCyclic_Calls_Init_On_First_Call
            // Arrange: Setup valid configuration
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            
            // Act: Call RunCyclic without explicit Init
            equipment.RunCyclic();
            
            // Assert: Init should have been called automatically
            Equal(expected := TRUE, actual := equipment.InitUserCalled);
        END_METHOD

        /// <summary>
        /// Test: Verifies that RunCyclic executes the abstract RunCyclicUserCode method.
        /// This is where derived classes implement their cyclic logic.
        /// </summary>
        {Test}
        METHOD PUBLIC RunCyclic_Calls_RunCyclicUserCode
            // Arrange: Setup valid configuration
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            
            // Act: Execute one cycle
            equipment.RunCyclic();
            
            // Assert: User code should have been executed
            Equal(expected := TRUE, actual := equipment.RunCyclicUserCodeCalled);
        END_METHOD

        /// <summary>
        /// Test: Verifies that user code is not executed when ConfigError is set.
        /// This prevents equipment from running in an invalid configuration state.
        /// </summary>
        {Test}
        METHOD PUBLIC RunCyclic_Does_Not_Call_UserCode_On_ConfigError
            // Arrange: Create invalid configuration (NULL mode causes ConfigError)
            equipment.Mode := NULL;
            
            // Act: Attempt to run cyclic
            equipment.RunCyclic();
            
            // Assert: User code should NOT be executed
            Equal(expected := FALSE, actual := equipment.RunCyclicUserCodeCalled);
        END_METHOD

        /// <summary>
        /// Test: Verifies that initialization only happens once across multiple cycles.
        /// Repeated calls to RunCyclic should not re-initialize the equipment.
        /// </summary>
        {Test}
        METHOD PUBLIC RunCyclic_Multiple_Calls_Only_Init_Once
            // Arrange: Setup valid configuration
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            
            // Act: Execute multiple cycles
            equipment.RunCyclic();
            equipment.RunCyclic();
            equipment.RunCyclic();
            
            // Assert: Init should have been called exactly once
            Equal(expected := 1, actual := equipment.InitUserCallCount);
        END_METHOD

        /// <summary>
        /// Test: Verifies that user code executes on every cycle.
        /// Each call to RunCyclic should execute RunCyclicUserCode once.
        /// </summary>
        {Test}
        METHOD PUBLIC RunCyclic_Multiple_Calls_Execute_UserCode_Multiple_Times
            // Arrange: Setup valid configuration
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            
            // Act: Execute three cycles
            equipment.RunCyclic();
            equipment.RunCyclic();
            equipment.RunCyclic();
            
            // Assert: User code should have been called three times
            Equal(expected := 3, actual := equipment.RunCyclicUserCodeCallCount);
        END_METHOD

        // ========================================
        // Error Handling Tests
        // ========================================

        /// <summary>
        /// Test: Verifies that equipment has no error in initial state.
        /// Fresh equipment instances should start without errors.
        /// </summary>
        {Test}
        METHOD PUBLIC HasError_Returns_False_Initially
            // Assert: No error should be present initially
            Equal(expected := FALSE, actual := equipment.HasError());
        END_METHOD

        /// <summary>
        /// Test: Verifies that HasError returns TRUE after SetError is called.
        /// This confirms error state tracking works correctly.
        /// </summary>
        {Test}
        METHOD PUBLIC HasError_Returns_True_After_SetError
            // Arrange: Initialize equipment
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            equipment.RunCyclic();
            
            // Act: Set an error state
            equipment.SetError(errorState := ErrorState#OtherError);
            equipment.RunCyclic(); // Update _hasError flag
            
            // Assert: Error should be detected
            Equal(expected := TRUE, actual := equipment.HasError());
        END_METHOD

        /// <summary>
        /// Test: Verifies that SetError properly sets the error state.
        /// Tests with ConfigError specifically.
        /// </summary>
        {Test}
        METHOD PUBLIC SetError_Sets_Error_State
            // Arrange: Initialize equipment
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            equipment.RunCyclic();
            
            // Act: Set configuration error
            equipment.SetError(errorState := ErrorState#ConfigError);
            equipment.RunCyclic(); // Update _hasError flag
            
            // Assert: Error should be present
            Equal(expected := TRUE, actual := equipment.HasError());
        END_METHOD

        {Test}
        /// <summary>
        /// Test: Verifies that GetError returns NoError by default.
        /// Fresh equipment should have no error code set.
        /// </summary>
        METHOD PUBLIC GetError_Returns_NoError_By_Default
            VAR
                errorCode : WORD;
            END_VAR
            
            // Act: Get error code
            errorCode := equipment.GetError();
            
            // Assert: Should be NoError
            Equal(expected := ErrorState#NoError, actual := errorCode);
        END_METHOD

        /// <summary>
        /// Test: Verifies that GetError returns the correct error code after SetError.
        /// </summary>
        {Test}
        METHOD PUBLIC GetError_Returns_Set_Error_Code
            VAR
                errorCode : WORD;
            END_VAR
            
            // Act: Set an error and get it back
            equipment.SetError(errorState := ErrorState#OtherError);
            errorCode := equipment.GetError();
            
            // Assert: Should return the set error code
            Equal(expected := ErrorState#OtherError, actual := errorCode);
        END_METHOD

        /// <summary>
        /// Test: Verifies that SetError with error text stores the message.
        /// </summary>
        {Test}
        METHOD PUBLIC SetError_With_Text_Stores_Message
            VAR
                errorText : STRING[30];
            END_VAR
            
            // Act: Set error with text
            equipment.SetError(errorState := ErrorState#OtherError, errorText := 'Motor overload');
            errorText := equipment.GetErrorText();
            
            // Assert: Error text should be stored
            Equal(expected := 'Motor overload', actual := errorText);
        END_METHOD

        /// <summary>
        /// Test: Verifies that SetError without text clears the error message.
        /// </summary>
        {Test}
        METHOD PUBLIC SetError_Without_Text_Clears_Message
            VAR
                errorText : STRING[30];
            END_VAR
            
            // Arrange: Set error with text first
            equipment.SetError(errorState := ErrorState#OtherError, errorText := 'Initial error');
            
            // Act: Set new error without text
            equipment.SetError(errorState := ErrorState#ConfigError);
            errorText := equipment.GetErrorText();
            
            // Assert: Error text should be empty
            Equal(expected := '', actual := errorText);
        END_METHOD

        /// <summary>
        /// Test: Verifies that GetErrorText returns empty string by default.
        /// </summary>
        {Test}
        METHOD PUBLIC GetErrorText_Returns_Empty_By_Default
            VAR
                errorText : STRING[30];
            END_VAR
            
            // Act: Get error text without setting error
            errorText := equipment.GetErrorText();
            
            // Assert: Should be empty
            Equal(expected := '', actual := errorText);
        END_METHOD

        /// <summary>
        /// Test: Verifies that ResetFault clears the error state.
        /// </summary>
        {Test}
        METHOD PUBLIC ResetFault_Clears_Error_State
            // Arrange: Set an error
            equipment.SetError(errorState := ErrorState#OtherError);
            
            // Act: Reset fault
            equipment.ResetFault();
            
            // Assert: Error should be cleared
            Equal(expected := FALSE, actual := equipment.HasError());
        END_METHOD

        /// <summary>
        /// Test: Verifies that ResetFault clears the error message.
        /// </summary>
        {Test}
        METHOD PUBLIC ResetFault_Clears_Error_Message
            VAR
                errorText : STRING[30];
            END_VAR
            
            // Arrange: Set error with text
            equipment.SetError(errorState := ErrorState#OtherError, errorText := 'Test error');
            
            // Act: Reset fault
            equipment.ResetFault();
            errorText := equipment.GetErrorText();
            
            // Assert: Error text should be cleared
            Equal(expected := '', actual := errorText);
        END_METHOD

        /// <summary>
        /// Test: Verifies that ResetFault clears both error code and message.
        /// </summary>
        {Test}
        METHOD PUBLIC ResetFault_Clears_Both_Error_And_Message
            VAR
                errorCode : WORD;
                errorText : STRING[30];
            END_VAR
            
            // Arrange: Set error with text
            equipment.SetError(errorState := ErrorState#OtherError, errorText := 'Critical fault');
            
            // Act: Reset fault
            equipment.ResetFault();
            errorCode := equipment.GetError();
            errorText := equipment.GetErrorText();
            
            // Assert: Both should be cleared
            Equal(expected := ErrorState#NoError, actual := errorCode);
            Equal(expected := '', actual := errorText);
        END_METHOD

        // ========================================
        // Startup Status Tests
        // ========================================

        /// <summary>
        /// Test: Verifies that GetStartupStatus returns InternalError before initialization.
        /// Uninitialized equipment cannot provide valid startup status.
        /// </summary>
        {Test}
        METHOD PUBLIC GetStartupStatus_Returns_InternalError_Before_Init
            VAR
                status : StartUpStatus;
            END_VAR
            
            // Act: Get status without initialization
            status := equipment.GetStartupStatus();
            
            // Assert: Should return InternalError
            EqualStartUpStatus(expected := StartUpStatus#InternalError, actual := status);
        END_METHOD

        /// <summary>
        /// Test: Verifies that GetStartupStatus returns valid status after initialization.
        /// Once initialized, equipment should provide meaningful startup status.
        /// </summary>
        {Test}
        METHOD PUBLIC GetStartupStatus_Returns_Valid_After_Init
            VAR
                status : StartUpStatus;
            END_VAR
            // Arrange: Setup and initialize equipment
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            equipment.ExternalRelease := releaseTrue;
            
            // Act: Initialize via RunCyclic (Init is private) and get status
            equipment.RunCyclic();
            status := equipment.GetStartupStatus();
            
            // Assert: Should not be InternalError anymore
            Equal(expected := FALSE, actual := status = StartUpStatus#InternalError);
        END_METHOD

        /// <summary>
        /// Test: Verifies that startup status is NotReleased when release condition is false.
        /// Equipment in manual mode without release should report NotReleased status.
        /// </summary>
        {Test}
        METHOD PUBLIC GetStartupStatus_NotReleased_When_Release_Is_False
            VAR
                status : StartUpStatus;
            END_VAR
            // Arrange: Setup with manual mode and false release
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Manual;
            equipment.ExternalRelease := releaseFalse;
            
            // Act: Run cycle (initializes automatically) and get status
            equipment.RunCyclic();
            equipment.RunCyclic(); // Second cycle to ensure startup system is fully initialized
            status := equipment.GetStartupStatus();
            
            // Assert: Should be Manual (not NotReleased) when in Manual mode
            EqualStartUpStatus(expected := StartUpStatus#Manual, actual := status);
        END_METHOD

        // ========================================
        // Release Configuration Tests
        // ========================================

        /// <summary>
        /// Test: Verifies that external release is properly configured in default auto startup.
        /// When no external auto startup is provided, the default should use external release.
        /// </summary>
        {Test}
        METHOD PUBLIC Init_With_ExternalRelease_Configures_DefaultAutoStartup
            // Arrange: Setup with external release but no external auto startup
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            equipment.ExternalRelease := releaseTrue;
            equipment.ExternalAutoStartup := NULL;
            
            // Act: Initialize equipment via RunCyclic (Init is private)
            equipment.RunCyclic();
            
            // Assert: Should initialize successfully
            Equal(expected := TRUE, actual := equipment.InitUserCalled);
        END_METHOD

        /// <summary>
        /// Test: Verifies null-object pattern for release.
        /// When no external release is provided, equipment uses AlwaysReleased internally.
        /// </summary>
        {Test}
        METHOD PUBLIC Init_Without_ExternalRelease_Uses_AlwaysReleased
            // Arrange: Setup without external release or auto startup
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            equipment.ExternalRelease := NULL;
            equipment.ExternalAutoStartup := NULL;
            
            // Act: Initialize equipment via RunCyclic (Init is private)
            equipment.RunCyclic();
            
            // Assert: Should initialize successfully with null-object pattern
            Equal(expected := TRUE, actual := equipment.InitUserCalled);
        END_METHOD

        // ========================================
        // StartUpTime Configuration Tests
        // ========================================

        /// <summary>
        /// Test: Verifies that default startup time is 5 seconds.
        /// This is the standard startup warning time for equipment.
        /// </summary>
        {Test}
        METHOD PUBLIC StartUpTime_Default_Is_5_Seconds
            VAR
                expectedTime : TIME := T#5s;
            END_VAR
            
            // Assert: Default should be 5 seconds
            Equal(expected := expectedTime, actual := equipment.StartUpTime);
        END_METHOD

        /// <summary>
        /// Test: Verifies that startup time can be customized.
        /// Different equipment may require different startup warning periods.
        /// </summary>
        {Test}
        METHOD PUBLIC StartUpTime_Can_Be_Changed
            VAR
                customTime : TIME := T#10s;
            END_VAR
            
            // Act: Set custom startup time
            equipment.StartUpTime := customTime;
            
            // Assert: Should reflect the new value
            Equal(expected := customTime, actual := equipment.StartUpTime);
        END_METHOD

        // ========================================
        // Integration Tests
        // ========================================

        /// <summary>
        /// Test: Verifies complete lifecycle from initialization through multiple cycles.
        /// This integration test ensures all components work together correctly.
        /// </summary>
        {Test}
        METHOD PUBLIC Full_Lifecycle_Without_Errors
            // Arrange: Setup valid configuration
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            equipment.ExternalRelease := releaseTrue;
            
            // Act: Initialize via first RunCyclic
            equipment.RunCyclic();
            Equal(expected := TRUE, actual := equipment.InitUserCalled);
            
            // Act: Run multiple additional cycles
            equipment.RunCyclic();
            equipment.RunCyclic();
            
            // Assert: No errors and correct execution count
            Equal(expected := FALSE, actual := equipment.HasError());
            Equal(expected := 3, actual := equipment.RunCyclicUserCodeCallCount);
        END_METHOD

        /// <summary>
        /// Test: Verifies that error state prevents user code execution.
        /// When ConfigError is set, equipment should not execute cyclic user code.
        /// </summary>
        {Test}
        METHOD PUBLIC Error_State_Prevents_UserCode_Execution
            // Arrange: Initialize equipment normally
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Automatic;
            
            equipment.RunCyclic();
            equipment.ResetTestFlags();
            
            // Act: Set config error and try to run
            equipment.SetError(errorState := ErrorState#ConfigError);
            equipment.RunCyclic();
            
            // Assert: UserCode should not be called
            Equal(expected := FALSE, actual := equipment.RunCyclicUserCodeCalled);
        END_METHOD

        /// <summary>
        /// Test: Verifies that equipment continues to work after mode change.
        /// Switching from Manual to Automatic should not break functionality.
        /// </summary>
        {Test}
        METHOD PUBLIC Mode_Change_From_Manual_To_Automatic
            VAR
                status : StartUpStatus;
            END_VAR
            // Arrange: Initialize in manual mode
            equipment.Mode := mockMode;
            mockMode.mode := OperatingModes#Manual;
            equipment.ExternalRelease := releaseTrue;
            
            equipment.RunCyclic();
            
            // Act: Switch to automatic mode
            mockMode.mode := OperatingModes#Automatic;
            equipment.RunCyclic();
            
            // Assert: Should still execute user code
            Equal(expected := TRUE, actual := equipment.RunCyclicUserCodeCalled);
        END_METHOD

    END_CLASS

END_NAMESPACE
