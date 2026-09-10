USING Simatic.Ax.AutomationBase;

NAMESPACE Examples

    /// Beispielprogramm für die Verwendung der AxisSupervision Klasse
    PROGRAM AxisSupervisionExample
        VAR
            // Achsenüberwachung Instanz
            axis_supervision : AxisSupervision;
            
            // Simulierte Achsendaten
            axis_current_pos : REAL;      // Aktuelle Position der Achse
            axis_target_pos : REAL;       // Zielposition
            axis_start_pos : REAL;        // Startposition
            
            // Steuerungsvariablen
            start_movement : BOOL;        // Trigger zum Starten der Bewegung
            reset_error : BOOL;           // Trigger zum Zurücksetzen von Fehlern
            
            // Statusvariablen
            movement_active : BOOL;
            error_occurred : BOOL;
            error_code : SupervisionError;
            
            // Simulationsvariablen
            simulate_movement : BOOL := TRUE;
            movement_speed : REAL;        // Geschwindigkeit der simulierten Bewegung
        END_VAR
        
        //=============================================================================
        // INITIALISIERUNG (einmalig beim Start)
        //=============================================================================
        
        // Konfiguration der Überwachungsparameter
        axis_supervision.t_action := T#3s;      // 3 Sekunden bis Startposition verlassen werden muss
        axis_supervision.t_reaction := T#10s;   // 10 Sekunden bis Zielposition erreicht werden muss
        axis_supervision.tolerance := REAL#0.5; // Toleranz von 0.5 Einheiten
        
        //=============================================================================
        // ZYKLISCHE AUSFÜHRUNG
        //=============================================================================
        
        // Positionen an Überwachung übergeben
        axis_supervision.current_position := axis_current_pos;
        axis_supervision.start_position := axis_start_pos;
        axis_supervision.target_position := axis_target_pos;
        
        // Bewegung starten
        IF start_movement AND NOT movement_active THEN
            // Setze Startposition auf aktuelle Position
            axis_start_pos := axis_current_pos;
            
            // Starte Überwachung
            axis_supervision.StartSupervision();
            movement_active := TRUE;
            start_movement := FALSE;
        END_IF;
        
        // Überwachung ausführen (muss zyklisch aufgerufen werden)
        axis_supervision.Execute();
        
        // Bewegungssimulation (in echter Anwendung durch echte Achsensteuerung ersetzen)
        IF simulate_movement AND movement_active THEN
            THIS.SimulateAxisMovement();
        END_IF;
        
        // Status auslesen
        error_occurred := axis_supervision.HasError();
        error_code := axis_supervision.GetError();
        
        // Fehlerbehandlung
        IF error_occurred THEN
            movement_active := FALSE;
            
            // Fehlerausgabe
            CASE error_code OF
                SupervisionError#ERROR_ACTION_TIMEOUT:
                    // Fehler: Achse hat Startposition nicht rechtzeitig verlassen
                    // Hier könnte z.B. eine Alarmmeldung ausgegeben werden
                    ;
                    
                SupervisionError#ERROR_REACTION_TIMEOUT:
                    // Fehler: Achse hat Zielposition nicht rechtzeitig erreicht
                    // Hier könnte z.B. eine Alarmmeldung ausgegeben werden
                    ;
            END_CASE;
        END_IF;
        
        // Fehler zurücksetzen
        IF reset_error THEN
            axis_supervision.ResetError();
            error_occurred := FALSE;
            error_code := SupervisionError#NO_ERROR;
            reset_error := FALSE;
        END_IF;
        
        // Bewegung erfolgreich abgeschlossen
        IF axis_supervision.HasReachedTarget() THEN
            movement_active := FALSE;
        END_IF;
        
    END_PROGRAM
    
    /// Simuliert eine Achsenbewegung (nur für Demonstrationszwecke)
    METHOD PRIVATE SimulateAxisMovement
        VAR_TEMP
            distance_to_target : REAL;
            direction : REAL;
        END_VAR
        
        // Berechne Distanz und Richtung zum Ziel
        distance_to_target := axis_target_pos - axis_current_pos;
        
        IF Abs(distance_to_target) > axis_supervision.tolerance THEN
            // Bestimme Bewegungsrichtung
            IF distance_to_target > REAL#0.0 THEN
                direction := REAL#1.0;
            ELSE
                direction := REAL#-1.0;
            END_IF;
            
            // Bewege Achse (Geschwindigkeit: 1.0 Einheiten pro Zyklus)
            movement_speed := REAL#1.0;
            axis_current_pos := axis_current_pos + (direction * movement_speed);
        END_IF;
    END_METHOD

END_NAMESPACE
