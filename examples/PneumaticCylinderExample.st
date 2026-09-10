USING Simatic.Ax.AutomationBase;

NAMESPACE Examples

    /// Beispielprogramm für die Verwendung der AxisSupervision Klasse
    /// Zeigt die Überwachung eines Pneumatikzylinders mit Endschaltern
    PROGRAM PneumaticCylinderSupervisionExample
        VAR
            // Achsenüberwachung Instanz
            cylinder_supervision : AxisSupervision;
            
            // Pneumatikzylinder Steuerung
            cylinder_extend : BOOL;           // Ausfahren-Signal
            cylinder_retract : BOOL;          // Einfahren-Signal
            
            // Endschalter (Sensoren)
            sensor_retracted : BOOL;          // Endschalter: Zylinder eingefahren
            sensor_extended : BOOL;           // Endschalter: Zylinder ausgefahren
            
            // Steuerungsvariablen
            start_extend : BOOL;              // Trigger zum Ausfahren
            start_retract : BOOL;             // Trigger zum Einfahren
            reset_error : BOOL;               // Trigger zum Zurücksetzen von Fehlern
            
            // Statusvariablen
            movement_active : BOOL;
            error_occurred : BOOL;
            error_code : SupervisionError;
            cylinder_state : CylinderState;
        END_VAR
        
        //=============================================================================
        // INITIALISIERUNG (einmalig beim Start)
        //=============================================================================
        
        // Konfiguration der Überwachungsparameter
        cylinder_supervision.t_action := T#2s;      // 2 Sekunden bis Bewegung beginnt
        cylinder_supervision.t_reaction := T#5s;    // 5 Sekunden bis Endposition erreicht
        
        //=============================================================================
        // ZYKLISCHE AUSFÜHRUNG
        //=============================================================================
        
        // Ausfahren starten
        IF start_extend AND NOT movement_active AND NOT error_occurred THEN
            IF sensor_retracted THEN  // Nur ausfahren, wenn eingefahren
                cylinder_extend := TRUE;
                cylinder_retract := FALSE;
                
                // Überwachung konfigurieren und starten
                // has_left_start = TRUE, wenn Zylinder nicht mehr eingefahren ist
                // has_reached_target = TRUE, wenn Zylinder ausgefahren ist
                cylinder_supervision.StartSupervision();
                movement_active := TRUE;
                cylinder_state := CylinderState#Extending;
            END_IF;
            start_extend := FALSE;
        END_IF;
        
        // Einfahren starten
        IF start_retract AND NOT movement_active AND NOT error_occurred THEN
            IF sensor_extended THEN  // Nur einfahren, wenn ausgefahren
                cylinder_extend := FALSE;
                cylinder_retract := TRUE;
                
                // Überwachung konfigurieren und starten
                cylinder_supervision.StartSupervision();
                movement_active := TRUE;
                cylinder_state := CylinderState#Retracting;
            END_IF;
            start_retract := FALSE;
        END_IF;
        
        // Signale für Überwachung setzen (abhängig von Bewegungsrichtung)
        CASE cylinder_state OF
            CylinderState#Extending:
                // Beim Ausfahren:
                // - Startposition verlassen = Sensor "eingefahren" nicht mehr aktiv
                // - Zielposition erreicht = Sensor "ausgefahren" aktiv
                cylinder_supervision.has_left_start := NOT sensor_retracted;
                cylinder_supervision.has_reached_target := sensor_extended;
                
            CylinderState#Retracting:
                // Beim Einfahren:
                // - Startposition verlassen = Sensor "ausgefahren" nicht mehr aktiv
                // - Zielposition erreicht = Sensor "eingefahren" aktiv
                cylinder_supervision.has_left_start := NOT sensor_extended;
                cylinder_supervision.has_reached_target := sensor_retracted;
                
            CylinderState#Idle:
                cylinder_supervision.has_left_start := FALSE;
                cylinder_supervision.has_reached_target := FALSE;
        END_CASE;
        
        // Überwachung ausführen (muss zyklisch aufgerufen werden)
        cylinder_supervision.Execute();
        
        // Status auslesen
        error_occurred := cylinder_supervision.HasError();
        error_code := cylinder_supervision.GetError();
        
        // Fehlerbehandlung
        IF error_occurred THEN
            // Zylinder stoppen
            cylinder_extend := FALSE;
            cylinder_retract := FALSE;
            movement_active := FALSE;
            cylinder_state := CylinderState#Error;
            
            // Fehlerausgabe
            CASE error_code OF
                SupervisionError#ERROR_ACTION_TIMEOUT:
                    // Fehler: Zylinder hat Startposition nicht rechtzeitig verlassen
                    // Mögliche Ursachen:
                    // - Ventil defekt
                    // - Zylinder blockiert
                    // - Sensor defekt
                    ;
                    
                SupervisionError#ERROR_REACTION_TIMEOUT:
                    // Fehler: Zylinder hat Zielposition nicht rechtzeitig erreicht
                    // Mögliche Ursachen:
                    // - Zylinder zu langsam
                    // - Mechanische Blockierung
                    // - Sensor defekt
                    // - Druckluft zu niedrig
                    ;
            END_CASE;
        END_IF;
        
        // Fehler zurücksetzen
        IF reset_error THEN
            cylinder_supervision.ResetError();
            error_occurred := FALSE;
            error_code := SupervisionError#NO_ERROR;
            cylinder_state := CylinderState#Idle;
            reset_error := FALSE;
        END_IF;
        
        // Bewegung erfolgreich abgeschlossen
        IF cylinder_supervision.HasReachedTarget() AND movement_active THEN
            cylinder_extend := FALSE;
            cylinder_retract := FALSE;
            movement_active := FALSE;
            cylinder_state := CylinderState#Idle;
        END_IF;
        
    END_PROGRAM
    
    /// Zustände des Pneumatikzylinders
    TYPE
        CylinderState : INT (
            Idle := 0,          // Ruhezustand
            Extending := 1,     // Ausfahren
            Retracting := 2,    // Einfahren
            Error := 99         // Fehlerzustand
        ) := Idle;
    END_TYPE

END_NAMESPACE
