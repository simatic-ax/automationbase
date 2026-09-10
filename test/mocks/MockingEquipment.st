USING Simatic.Ax.AutomationBase;
NAMESPACE Simatic.Ax.Conveyor.Mocks

    CLASS MockEquiment
        IMPLEMENTS IEquipmentBase
        VAR PUBLIC
            MockError : BOOL;
            MockStatus : StartUpStatus;
        END_VAR
        VAR PROTECTED
            _error : BOOL;
            _errorText : STRING[30];
        END_VAR

        METHOD PUBLIC HasError : BOOL
            HasError := MockError;
        END_METHOD

        METHOD PUBLIC GetStartupStatus : StartUpStatus
            GetStartupStatus := MockStatus;
        END_METHOD

        METHOD PUBLIC GetError : ErrorState
            ;
        END_METHOD
        
        METHOD PUBLIC GetErrorText : STRING[30]
            GetErrorText := _errorText;
        END_METHOD
        
        METHOD PUBLIC Init
            ;
        END_METHOD
        
        METHOD PUBLIC RunCyclic
            ;
        END_METHOD

        METHOD PUBLIC ResetFault
            _error := FALSE;
            _errorText := '';
        END_METHOD

        METHOD PUBLIC SetError
            VAR_INPUT
                errorState : ErrorState;
            END_VAR
            _error := TRUE;
            _errorText := '';
        END_METHOD
        
        METHOD PUBLIC SetError
            VAR_INPUT
                errorState : ErrorState;
                errorText : STRING[30];
            END_VAR
            _error := TRUE;
            _errorText := errorText;
        END_METHOD
    END_CLASS

END_NAMESPACE
