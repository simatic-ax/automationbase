USING System.Timer;
NAMESPACE Simatic.Ax.AutomationBase
    
    {axcode:docs-v0:@simatic-ax/automationbase:StartupWarning.md}
    INTERFACE IAutoStartup
        METHOD Status : StartUpStatus
        END_METHOD
    END_INTERFACE
    // StartupTime per Equipment or per Zonemanager?
    // Decission: Each Equipment should have its own Startup.
    // Equipment knows its own startup time (it could be different between diffrent equipments)
    // and the after an error, only this equipment has execute an startup and not the whole zone which could be still in automatic
    CLASS INTERNAL EquipmentAutoStartup IMPLEMENTS IAutoStartup
        VAR PUBLIC
            StartUpTime : TIME := T#5s;
            Mode : IOperatingMode;
            Release : IRelease;
            Equipment : IEquipmentBase;
        END_VAR
        VAR PRIVATE
            _alwaysReleased : AlwaysReleasedRelease;
            _effectiveRelease : IRelease;
            _isInitialized : BOOL;
        END_VAR
        VAR PROTECTED
            ton : OnDelay;
            internalError : BOOL;
        END_VAR
        METHOD PUBLIC Status : StartUpStatus
            IF (internalError) THEN
                Status := StartUpStatus#InternalError;
                RETURN;
            END_IF;
            // Check if in Manual mode
            IF (Mode <> NULL) AND (Mode.GetOperatingMode() = OperatingModes#Manual) THEN
                Status := StartUpStatus#Manual;
                RETURN;
            END_IF;
            // Startup warning elapsed and in Automatic mode
            IF NOT(ton.output) AND ton.signal THEN
                Status := StartUpStatus#AutoStartingUp;
                RETURN;
            ELSIF (ton.output) THEN
                Status := StartUpStatus#AutoStartedUp;
                RETURN;
            ELSE
                Status := StartUpStatus#NotReleased;
                RETURN;
            END_IF;
        END_METHOD
        METHOD PUBLIC RunCyclic
            VAR_TEMP
                _runStartUpTimer : BOOL;
            END_VAR

            IF (NOT _isInitialized) THEN
                // Null-Object-Pattern: If Release is NULL, use AlwaysReleasedRelease
                IF (Release = NULL) THEN
                    _effectiveRelease := _alwaysReleased;
                ELSE
                    _effectiveRelease := Release;
                END_IF;                
                _isInitialized := TRUE;
            END_IF;

            IF (mode = NULL) OR (equipment = NULL) THEN
                internalError := TRUE;
                RETURN;
            END_IF;
            
            _runStartUpTimer := (mode.GetOperatingMode() = OperatingModes#Automatic);
            _runStartUpTimer := _runStartUpTimer AND _effectiveRelease.IsReleased();
            _runStartUpTimer := _runStartUpTimer AND NOT(equipment.HasError());
            ton(signal := _runStartUpTimer, duration := StartUpTime);
        END_METHOD
    END_CLASS

    TYPE
        StartUpStatus : (InternalError, NotReleased, Manual, AutoStartingUp, AutoStartedUp) := NotReleased;
    END_TYPE

END_NAMESPACE
