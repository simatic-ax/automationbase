USING AxUnit.ResultFunctions;
USING Simatic.Ax.AutomationBase;
USING System.Strings;

NAMESPACE Simatic.Ax.AutomationBase

    /// <summary>
    /// Custom assertion function for comparing StartUpStatus enum values.
    /// Provides clear error messages showing expected vs actual values with enum names.
    /// </summary>
    /// <param name="expected">The expected StartUpStatus value</param>
    /// <param name="actual">The actual StartUpStatus value to compare</param>
    /// <param name="file">Caller file path (automatically filled by compiler)</param>
    /// <param name="line">Caller line number (automatically filled by compiler)</param>
    FUNCTION PUBLIC EqualStartUpStatus
        VAR_INPUT
            expected : StartUpStatus;
            actual : StartUpStatus;
            {CallerFilePath}
            file : WSTRING[1024];
            {CallerLineNumber}
            line : INT;
        END_VAR
        VAR_TEMP
            message : STRING[254];
        END_VAR
        
        // If values match, test passes
        IF expected = actual THEN
            axunit_Succeed();
        ELSE
            // Build descriptive error message with enum names
            message := 'Expected StartUpStatus to be ';
            CASE expected OF
                StartUpStatus#InternalError:
                    message := Concat(message, 'InternalError');
                StartUpStatus#NotReleased:
                    message := Concat(message, 'NotReleased');
                StartUpStatus#AutoStartingUp:
                    message := Concat(message, 'AutoStartingUp');
                StartUpStatus#AutoStartedUp:
                    message := Concat(message, 'AutoStartedUp');
            END_CASE;
            message := Concat(message, ' but was ');
            CASE actual OF
                StartUpStatus#InternalError:
                    message := Concat(message, 'InternalError');
                StartUpStatus#NotReleased:
                    message := Concat(message, 'NotReleased');
                StartUpStatus#AutoStartingUp:
                    message := Concat(message, 'AutoStartingUp');
                StartUpStatus#AutoStartedUp:
                    message := Concat(message, 'AutoStartedUp');
            END_CASE;
            // Report test failure with descriptive message
            axunit_Fail(message, file, line);
        END_IF;
    END_FUNCTION

END_NAMESPACE
