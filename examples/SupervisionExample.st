USING Simatic.Ax.AutomationBase;

NAMESPACE Examples

    /// Universelles Beispielprogramm für die Verwendung der Supervision Klasse
    /// Zeigt verschiedene Anwendungsfälle der generischen Überwachung
    PROGRAM SupervisionExample
        VAR
            //=============================================================================
            // Beispiel 1: Pneumatikzylinder ausfahren
            //=============================================================================
            supervision_cylinder_extend : Supervision;
            cylinder_extend_valve : BOOL;           // Ventil zum Ausfahren
            cylinder_sensor_extended : BOOL;        // Sensor: Zylinder ausgefahren
            start_cylinder_extend : BOOL;           // Trigger
            
            //=============================================================================
            // Beispiel 2: Motor starten
            //=============================================================================
            supervision_motor_start : Supervision;
            motor_start_command : BOOL;             // Startbefehl für Motor
            motor_running_feedback : BOOL;          // Rückmeldung: Motor läuft
            start_motor : BOOL;                     // Trigger
            
            //=============================================================================
            // Beispiel 3: Ventil schließen
            //=============================================================================
            supervision_valve_close : Supervision;
            valve_close_command : BOOL;             // Befehl zum Schließen
            valve_closed_sensor : BOOL;             // Sensor: Ventil geschlossen
            close_valve : BOOL;                     // Trigger
            
            //=============================================================================
            // Beispiel 4: Sensor-Überwachung (Signal soll inaktiv werden)
            //=============================================================================
            supervision_sensor_clear : Supervision;
            sensor_signal : BOOL;                   // Zu überwachender Sensor
            wait_for_sensor_clear : BOOL;           // Trigger
            
            //=============================================================================
            // Beispiel 5: Zweistufige Überwachung (Aktion + Reaktion)
            //=============================================================================
            supervision_action : Supervision;       // Überwacht: Bewegung beginnt
            supervision_reaction : Supervision;     // Überwacht: Bewegung endet
            actuator_command : BOOL;                // Befehl an Aktuator
            actuator_start_sensor : BOOL;           // Sensor: Startposition verlassen
            actuator_target_sensor : BOOL;          // Sensor: Zielposition erreicht
            start_actuator : BOOL;                  // Trigger
            
            // Gemeinsame Variablen
            reset_errors : BOOL;                    // Reset für alle Fehler
        END_VAR
        
        //=============================================================================
        // BEISPIEL 1: PNEUMATIKZYLINDER AUSFAHREN
        // Überwacht, ob Sensor "ausgefahren" innerhalb von 5 Sekunden aktiv wird
        //=============================================================================
        
        // Konfiguration (einmalig)
        supervision_cylinder_extend.timeout := T#5s;
        supervision_cylinder_extend.behavior := SupervisionBehavior#Action;  // Signal soll TRUE werden
        
        // Bewegung starten
        IF start_cylinder_extend THEN
            cylinder_extend_valve := TRUE;
            supervision_cylinder_extend.Start();
            start_cylinder_extend := FALSE;
        END_IF;
        
        // Zyklisch: Signal übergeben und überwachen
        supervision_cylinder_extend.Execute(signal := cylinder_sensor_extended);
        
        // Fehlerbehandlung
        IF supervision_cylinder_extend.HasError() THEN
            cylinder_extend_valve := FALSE;
            // Fehler: Zylinder hat Endposition nicht erreicht
        END_IF;
        
        // Erfolgreich abgeschlossen
        IF supervision_cylinder_extend.IsCompleted() THEN
            // Zylinder ist ausgefahren
        END_IF;
        
        //=============================================================================
        // BEISPIEL 2: MOTOR STARTEN
        // Überwacht, ob Motor-Rückmeldung innerhalb von 3 Sekunden aktiv wird
        //=============================================================================
        
        // Konfiguration
        supervision_motor_start.timeout := T#3s;
        supervision_motor_start.behavior := SupervisionBehavior#Action;
        
        // Motor starten
        IF start_motor THEN
            motor_start_command := TRUE;
            supervision_motor_start.Start();
            start_motor := FALSE;
        END_IF;
        
        // Zyklisch überwachen
        supervision_motor_start.Execute(signal := motor_running_feedback);
        
        IF supervision_motor_start.HasError() THEN
            motor_start_command := FALSE;
            // Fehler: Motor hat nicht gestartet
        END_IF;
        
        //=============================================================================
        // BEISPIEL 3: VENTIL SCHLIESSEN
        // Überwacht, ob Ventil innerhalb von 2 Sekunden geschlossen ist
        //=============================================================================
        
        // Konfiguration
        supervision_valve_close.timeout := T#2s;
        supervision_valve_close.behavior := SupervisionBehavior#Action;
        
        // Ventil schließen
        IF close_valve THEN
            valve_close_command := TRUE;
            supervision_valve_close.Start();
            close_valve := FALSE;
        END_IF;
        
        // Zyklisch überwachen
        supervision_valve_close.Execute(signal := valve_closed_sensor);
        
        IF supervision_valve_close.HasError() THEN
            // Fehler: Ventil hat nicht geschlossen
        END_IF;
        
        //=============================================================================
        // BEISPIEL 4: SENSOR-ÜBERWACHUNG (Signal soll inaktiv werden)
        // Überwacht, ob Sensor innerhalb von 10 Sekunden inaktiv wird
        //=============================================================================
        
        // Konfiguration
        supervision_sensor_clear.timeout := T#10s;
        supervision_sensor_clear.behavior := SupervisionBehavior#Reaction;  // Signal soll FALSE werden
        
        // Überwachung starten
        IF wait_for_sensor_clear THEN
            supervision_sensor_clear.Start();
            wait_for_sensor_clear := FALSE;
        END_IF;
        
        // Zyklisch überwachen
        supervision_sensor_clear.Execute(signal := sensor_signal);
        
        IF supervision_sensor_clear.HasError() THEN
            // Fehler: Sensor ist nicht inaktiv geworden
        END_IF;
        
        //=============================================================================
        // BEISPIEL 5: ZWEISTUFIGE ÜBERWACHUNG (Aktion + Reaktion)
        // Überwacht erst, ob Bewegung beginnt, dann ob sie endet
        //=============================================================================
        
        // Konfiguration
        supervision_action.timeout := T#2s;
        supervision_action.behavior := SupervisionBehavior#Action;      // Startposition verlassen
        supervision_reaction.timeout := T#10s;
        supervision_reaction.behavior := SupervisionBehavior#Action;    // Zielposition erreichen
        
        // Bewegung starten
        IF start_actuator THEN
            actuator_command := TRUE;
            supervision_action.Start();
            start_actuator := FALSE;
        END_IF;
        
        // Phase 1: Aktionsüberwachung (Bewegung beginnt)
        IF supervision_action.IsActive() THEN
            supervision_action.Execute(signal := actuator_start_sensor);
            
            // Wenn Startposition verlassen, starte Reaktionsüberwachung
            IF supervision_action.IsCompleted() THEN
                supervision_reaction.Start();
            END_IF;
            
            IF supervision_action.HasError() THEN
                actuator_command := FALSE;
                // Fehler: Bewegung hat nicht begonnen
            END_IF;
        END_IF;
        
        // Phase 2: Reaktionsüberwachung (Bewegung endet)
        IF supervision_reaction.IsActive() THEN
            supervision_reaction.Execute(signal := actuator_target_sensor);
            
            IF supervision_reaction.IsCompleted() THEN
                actuator_command := FALSE;
                // Erfolgreich: Zielposition erreicht
            END_IF;
            
            IF supervision_reaction.HasError() THEN
                actuator_command := FALSE;
                // Fehler: Zielposition nicht erreicht
            END_IF;
        END_IF;
        
        //=============================================================================
        // GEMEINSAME FEHLERBEHANDLUNG
        //=============================================================================
        
        // Alle Fehler zurücksetzen
        IF reset_errors THEN
            supervision_cylinder_extend.Reset();
            supervision_motor_start.Reset();
            supervision_valve_close.Reset();
            supervision_sensor_clear.Reset();
            supervision_action.Reset();
            supervision_reaction.Reset();
            reset_errors := FALSE;
        END_IF;
        
    END_PROGRAM

END_NAMESPACE
