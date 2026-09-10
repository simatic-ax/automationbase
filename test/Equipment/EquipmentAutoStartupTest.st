USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;
NAMESPACE Simatic.Ax.AutomationBase
    {TestFixture}
    CLASS EquipmentAutoStartupTest
        VAR
            startup, startupStateless : EquipmentAutoStartup;
            mockMan, mockManStateless : MockOperatingMode;
            relTrue : MockIsReleased_TRUE;
            relFalse : MockIsReleased_FALSE;
            mockEquipment, mockEquipmentStateless : MockEquiment;
        END_VAR
        
        {TestSetup}
        METHOD PUBLIC TestSetup
            startup := startupStateless;
            mockEquipment := mockEquipmentStateless;
            mockMan := mockManStateless;
        END_METHOD

        {Test}
        METHOD PUBLIC StartupProhibitedOfError
            mockMan.mode := OperatingModes#Automatic;
            startup.Mode := mockMan;
            startup.Release := relTrue;
            startup.equipment := mockEquipment;
            mockEquipment.MockError := TRUE;

            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#NotReleased);
        END_METHOD
        {Test}
        METHOD PUBLIC StartupProhibitedOfNoRelease
            mockMan.mode := OperatingModes#Automatic;
            startup.Mode := mockMan;
            startup.Release := relFalse;
            startup.equipment := mockEquipment;
            
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#NotReleased);
        END_METHOD
        {Test}
        METHOD PUBLIC StartupProhibitedOfNoAutomatic
            mockMan.mode := OperatingModes#Commissioning;
            startup.Mode := mockMan;
            startup.Release := relTrue;
            startup.equipment := mockEquipment;
            
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#NotReleased);
        END_METHOD

        {Test}
        METHOD PUBLIC Startup_InProgress_after_switch_to_automatic
            mockMan.mode := OperatingModes#Commissioning;
            startup.Mode := mockMan;
            startup.Release := relTrue;
            startup.equipment := mockEquipment;
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#NotReleased);
            
            mockMan.mode := OperatingModes#Automatic;
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#AutoStartingUp);
        END_METHOD
        {Test}
        METHOD PUBLIC When_Automatic_And_No_Release_configured_returns_AutoStartingUp
            mockMan.mode := OperatingModes#Automatic;
            startup.Mode := mockMan;
            startup.Release := NULL;
            startup.equipment := mockEquipment;
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#AutoStartingUp);
        END_METHOD
        {Test}
        METHOD PUBLIC NotConfigured_Mode_returns_internalerror
            startup.Mode := NULL;
            startup.Release := relTrue;
            startup.equipment := mockEquipment;
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#InternalError);
        END_METHOD
        {Test}
        METHOD PUBLIC NotConfigured_Equipment_returns_internalerror
            startup.Mode := mockMan;
            startup.Release := relTrue;
            startup.equipment := NULL;
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#InternalError);
        END_METHOD

        {Test}
        METHOD PUBLIC Manual_Mode_returns_Manual_Status
            mockMan.mode := OperatingModes#Manual;
            startup.Mode := mockMan;
            startup.Release := relTrue;
            startup.equipment := mockEquipment;
            
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#Manual);
        END_METHOD

        {Test}
        METHOD PUBLIC Manual_Mode_with_Error_returns_Manual_Status
            mockMan.mode := OperatingModes#Manual;
            startup.Mode := mockMan;
            startup.Release := relTrue;
            startup.equipment := mockEquipment;
            mockEquipment.MockError := TRUE;
            
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#Manual);
        END_METHOD

        {Test}
        METHOD PUBLIC Manual_Mode_without_Release_returns_Manual_Status
            mockMan.mode := OperatingModes#Manual;
            startup.Mode := mockMan;
            startup.Release := relFalse;
            startup.equipment := mockEquipment;
            
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#Manual);
        END_METHOD

        {Test}
        METHOD PUBLIC Switch_from_Manual_to_Automatic_starts_Startup
            // First set to Manual
            mockMan.mode := OperatingModes#Manual;
            startup.Mode := mockMan;
            startup.Release := relTrue;
            startup.equipment := mockEquipment;
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#Manual);
            
            // Switch to Automatic
            mockMan.mode := OperatingModes#Automatic;
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#AutoStartingUp);
        END_METHOD

        {Test}
        METHOD PUBLIC Switch_from_Automatic_to_Manual_stops_Startup
            // First set to Automatic and start startup
            mockMan.mode := OperatingModes#Automatic;
            startup.Mode := mockMan;
            startup.Release := relTrue;
            startup.equipment := mockEquipment;
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#AutoStartingUp);
            
            // Switch to Manual
            mockMan.mode := OperatingModes#Manual;
            startup.RunCyclic();
            Equal(expected := TRUE , actual := startup.Status() = StartUpStatus#Manual);
        END_METHOD
    END_CLASS

END_NAMESPACE
