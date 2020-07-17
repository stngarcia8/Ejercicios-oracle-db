CREATE OR REPLACE TRIGGER trgAsignacionComisiones AFTER
INSERT OR
UPDATE OR
DELETE ON boleta FOR EACH ROW BEGIN IF inserting THEN
INSERT INTO COMISION_VENTA VALUES
        (
                :NEW.nro_boleta,
                ROUND(:NEW.monto_boleta*0.15)
        );

END IF;
IF updating THEN
        IF :NEW.monto_boleta>:OLD.monto_boleta THEN
                UPDATE
                        COMISION_VENTA
                SET     valor_comision=ROUND(:new.monto_boleta*0.15)
                WHERE
                        nro_boleta=:old.nro_boleta;a
        
        END IF;
END IF;
IF deleting THEN
        DELETE FROM COMISION_VENTA WHERE nro_boleta=:old.nro_boleta;

END IF;
END;
DECLARE
BEGIN
        INSERT INTO boleta VALUES
                (
                        28          ,
                        '16/06/2018',
                        258999      ,
                        3000        ,
                        12456905
                );
        
        UPDATE boleta SET monto_boleta=558590 WHERE nro_boleta=24;
        
        UPDATE boleta SET monto_boleta=60000 WHERE nro_boleta=27;
        
        DELETE FROM boleta WHERE nro_boleta=22;

END;