USING AxUnit.ResultFunctions;
USING Simatic.Ax.AutomationBase;
USING System.Strings;

NAMESPACE AutomationBase.Tests

    /// Assert für SupervisionError Enum
    FUNCTION PUBLIC EqualSupervisionError
        VAR_INPUT
            expected : SupervisionError;
            actual : SupervisionError;
            {CallerFilePath}
            file : WSTRING[1024];
            {CallerLineNumber}
            line : INT;
        END_VAR
        VAR_TEMP
            message : STRING[254];
        END_VAR
        
        IF expected = actual THEN
            axunit_Succeed();
        ELSE
            message := 'Expected SupervisionError to be ';
            CASE expected OF
                SupervisionError#NO_ERROR:
                    message := Concat(message, 'NO_ERROR');
                SupervisionError#TIMEOUT:
                    message := Concat(message, 'TIMEOUT');
            END_CASE;
            message := Concat(message, ' but was ');
            CASE actual OF
                SupervisionError#NO_ERROR:
                    message := Concat(message, 'NO_ERROR');
                SupervisionError#TIMEOUT:
                    message := Concat(message, 'TIMEOUT');
            END_CASE;
            axunit_Fail(message, file, line);
        END_IF;
    END_FUNCTION
    
    /// Assert für SupervisionBehavior Enum
    FUNCTION PUBLIC EqualSupervisionBehavior
        VAR_INPUT
            expected : SupervisionBehavior;
            actual : SupervisionBehavior;
            {CallerFilePath}
            file : WSTRING[1024];
            {CallerLineNumber}
            line : INT;
        END_VAR
        VAR_TEMP
            message : STRING[254];
        END_VAR
        
        IF expected = actual THEN
            axunit_Succeed();
        ELSE
            message := 'Expected SupervisionBehavior to be ';
            CASE expected OF
                SupervisionBehavior#Action:
                    message := Concat(message, 'Action');
                SupervisionBehavior#Reaction:
                    message := Concat(message, 'Reaction');
            END_CASE;
            message := Concat(message, ' but was ');
            CASE actual OF
                SupervisionBehavior#Action:
                    message := Concat(message, 'Action');
                SupervisionBehavior#Reaction:
                    message := Concat(message, 'Reaction');
            END_CASE;
            axunit_Fail(message, file, line);
        END_IF;
    END_FUNCTION

END_NAMESPACE
