USING Simatic.Ax.AutomationBase;

NAMESPACE Examples

    /// Beispielprogramm für die Verwendung der AxisSupervision Klasse
    /// Zeigt die Überwachung einer Servo-Achse mit Positionsrückmeldung
    PROGRAM ServoAxisSupervisionExample
        VAR
            // Achsenüberwachung Instanz
            axis_supervision : AxisSupervision;
            
            // Servo-Achse Daten
            axis_actual_position : REAL;      // Aktuelle Position der Achse
            axis_target_position : REAL;      // Zielposition
            axis_start_position : REAL;       // Startposition bei Bewegungsbeginn
            axis_tolerance : REAL := REAL#1.0; // Toleranz für "Position erreicht"
            
            // Steuerungsvariablen
            start_movement : BOOL;            // Trigger zum Starten der Bewegung
            reset_error : BOOL;               // Trigger zum Zurücksetzen von Fehlern
            
            // Statusvariablen
            movement_active : BOOL;
            error_occurred : BOOL;
            error_code : SupervisionError;
        END_VAR
        
        //=============================================================================
        // INITIALISIERUNG (einmalig beim Start)
        //=============================================================================
        
        // Konfiguration der Überwachungsparameter
        axis_supervision.t_action := T#1s;      // 1 Sekunde bis Achse beginnt sich zu bewegen
        axis_supervision.t_reaction := T#10s;   // 10 Sekunden bis Zielposition erreicht
        
        //=============================================================================
        // ZYKLISCHE AUSFÜHRUNG
        //=============================================================================
        
        // Bewegung starten
        IF start_movement AND NOT movement_active AND NOT error_occurred THEN
            // Startposition merken
            axis_start_position := axis_actual_position;
            
            // Überwachung starten
            axis_supervision.StartSupervision();
            movement_active := TRUE;
            start_movement := FALSE;
            
            // Hier würde die Achse den Fahrbefehl zur Zielposition erhalten
            // z.B. axis_controller.MoveAbsolute(axis_target_position);
        END_IF;
        
        // Signale für Überwachung berechnen
        IF movement_active THEN
            // Hat Achse Startposition verlassen? (außerhalb Toleranz)
            axis_supervision.has_left_start := 
                (Abs(axis_actual_position - axis_start_position) > axis_tolerance);
            
            // Hat Achse Zielposition erreicht? (innerhalb Toleranz)
            axis_supervision.has_reached_target := 
                (Abs(axis_actual_position - axis_target_position) <= axis_tolerance);
        ELSE
            axis_supervision.has_left_start := FALSE;
            axis_supervision.has_reached_target := FALSE;
        END_IF;
        
        // Überwachung ausführen (muss zyklisch aufgerufen werden)
        axis_supervision.Execute();
        
        // Status auslesen
        error_occurred := axis_supervision.HasError();
        error_code := axis_supervision.GetError();
        
        // Fehlerbehandlung
        IF error_occurred THEN
            movement_active := FALSE;
            
            // Hier würde die Achse gestoppt werden
            // z.B. axis_controller.Stop();
            
            // Fehlerausgabe
            CASE error_code OF
                SupervisionError#ERROR_ACTION_TIMEOUT:
                    // Fehler: Achse hat nicht begonnen sich zu bewegen
                    // Mögliche Ursachen:
                    // - Achse nicht freigegeben
                    // - Antrieb im Fehler
                    // - Mechanische Blockierung
                    ;
                    
                SupervisionError#ERROR_REACTION_TIMEOUT:
                    // Fehler: Achse hat Zielposition nicht rechtzeitig erreicht
                    // Mögliche Ursachen:
                    // - Achse zu langsam parametriert
                    // - Mechanische Blockierung
                    // - Last zu groß
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
        IF axis_supervision.HasReachedTarget() AND movement_active THEN
            movement_active := FALSE;
        END_IF;
        
    END_PROGRAM
    
    /// Hilfsfunktion für Absolutwert (falls System.Math nicht verfügbar)
    METHOD PRIVATE Abs : REAL
        VAR_INPUT
            value : REAL;
        END_VAR
        
        IF value < REAL#0.0 THEN
            Abs := -value;
        ELSE
            Abs := value;
        END_IF;
    END_METHOD

END_NAMESPACE
