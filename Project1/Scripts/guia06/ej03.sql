DECLARE
        CURSOR vCurEmpleados IS
                SELECT
                        employee_id                                                                 ,
                        hire_date                                                                   ,
                        (EXTRACT(YEAR FROM SYSDATE)-EXTRACT(YEAR FROM hire_date)) AS anos_trabajados,
                        salary                                                                      ,
                        0                              AS COLACION                                                               ,
                        0                              AS MOVILIZACION                                                           ,
                        (salary*NVL(commission_pct,0)) AS Valor_Comision                                                         ,
                        lo.country_id                  AS country_id
                FROM
                        employees EM
                JOIN
                        departments de
                ON
                        EM.department_id=de.department_id
                JOIN
                        locations lo
                ON
                        de.location_id=lo.location_id
                ORDER BY
                        employee_id;
        
        vEmpleado vCurEmpleados%rowtype;
        vTitulo       VARCHAR2(150);
        vMensajeError VARCHAR2(150);
        vFlagError    BOOLEAN DEFAULT FALSE;
        vValorCargas HABER_CALC_MES.VALOR_CARGAS_FAM%TYPE;
        vValorBonoPorAnos HABER_CALC_MES.VALOR_ASIG_ANNOS%TYPE;
        vValorBonoCostoVida HABER_CALC_MES.VALOR_COSTO_VIDA%TYPE DEFAULT 0;
        vPorcentajeCostoVida NUMBER(4,2) DEFAULT 0;
        vValorDescuentoSeguroSocial DESCUENTO_CALC_MES.VALOR_SEG_SOCIAL%TYPE;
        vValorDescuentoSalud DESCUENTO_CALC_MES.VALOR_SEG_SALUD%TYPE;
        vTotalHaberes TOTAL_CALC_MES.TOTAL_HABERES%TYPE;
        vTotalDescuentos TOTAL_CALC_MES.TOTAL_DESCUENTOS%TYPE;
BEGIN
        -- Limpiando tablas.
        DELETE FROM ERROR_CALC_REMUN;
        
        DELETE FROM HABER_CALC_MES;
        
        DELETE FROM DESCUENTO_CALC_MES;
        
        vTitulo:='| id_empleado | valor_salario | valor_com | valor_cargas_fam | valor_colacion | valor_movilizacion | valor_asig_anos | valor_costo_vida |';
        dbms_output.put_line('Tabla HABER_CALC_MES');
        dbms_output.put_line(rpad('-', LENGTH(vTitulo), '-'));
        dbms_output.put_line(vTitulo);
        dbms_output.put_line(rpad('-', LENGTH(vTitulo), '-'));
        OPEN vCurEmpleados;
        FETCH vCurEmpleados INTO vEmpleado;
        
        WHILE vCurEmpleados%found
        LOOP
                -- Limpiando y asignando valores.
                vEmpleado.colacion         :=700;
                vEmpleado.Movilizacion     :=300;
                vValorCargas               :=0;
                vValorBonoPorAnos          :=0;
                vValorBonoCostoVida        :=0;
                vValorDescuentoSeguroSocial:=0;
                vValorDescuentoSalud       :=0;
                vTotalDescuentos           :=0;
                vTotalHaberes              :=0;
                vMensajeError              :='';
                vFlagError                 :=FALSE;
                -- Procesando cargas familiares.
                DECLARE
                        CURSOR vCurCargas IS
                                SELECT
                                        CARGA_ID,
                                        FECHA_NACIMIENTO
                                FROM
                                        CARGAS_FAMILIARES
                                WHERE
                                        EMPLOYEE_ID=vEmpleado.employee_id
                                ORDER BY
                                        CARGA_ID;
                        
                        vCarga vCurCargas%rowtype;
                        vValor TRAMO_PAGO_CARGAS.VALOR_CARGA%TYPE;
                        vAnosCarga NUMBER(2);
                BEGIN
                        OPEN vCurCargas;
                        FETCH vCurCargas INTO vCarga;
                        
                        WHILE vCurCargas%found
                        LOOP
                                vFlagError   :=FALSE;
                                vMensajeError:='';
                                vValor       :=0;
                                vAnosCarga   :=extract(YEAR FROM SYSDATE)-extract(YEAR FROM vCarga.FECHA_NACIMIENTO);
                                BEGIN
                                        SELECT
                                                VALOR_CARGA
                                        INTO    vValor
                                        FROM
                                                TRAMO_PAGO_CARGAS
                                        WHERE
                                                vAnosCarga BETWEEN EDAD_INFERIOR AND     EDAD_SUPERIOR;
                                
                                EXCEPTION
                                WHEN TOO_MANY_ROWS THEN
                                        vMensajeError:='Se encontró más de un valor en tabla TRAMO_PAGO_CARGAS para la carga con identificación '
                                        ||TO_CHAR(vCarga.CARGA_ID,'99999');
                                        INSERT INTO ERROR_CALC_REMUN VALUES
                                                (
                                                (SELECT COUNT(*)+1 FROM ERROR_CALC_REMUN
                                                )
                                                ,
                                                vEmpleado.employee_id,
                                                vMensajeError
                                                );
                                        
                                        vFlagError:=true;
                                END;
                                IF vFlagError=FALSE THEN
                                        vValorCargas:=vValorCargas+vValor;
                                END IF;
                                FETCH vCurCargas INTO vCarga;
                        
                        END LOOP;
                        CLOSE vCurCargas;
                END;
                -- Procesando bono de asignacion por años.
                IF vEmpleado.anos_trabajados>9
                        AND
                        vEmpleado.salary<=10000 THEN
                        DECLARE
                                vPorcentajeAnos ANNOS_TRABAJADOS.PORCENTAJE%TYPE DEFAULT 0;
                        BEGIN
                                vFlagError   :=FALSE;
                                vMensajeError:='';
                                BEGIN
                                        SELECT
                                                PORCENTAJE
                                        INTO    vPorcentajeAnos
                                        FROM
                                                ANNOS_TRABAJADOS
                                        WHERE
                                                SALARIO_TOPE   >=vEmpleado.salary
                                        AND     ANNOS_CONTRATADO=vEmpleado.anos_trabajados
                                        AND     rownum          =1;
                                
                                EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                        vMensajeError:='No se encontró porcentaje en tabla ANNOS_TRABAJADOS para la combinación de años contratado v/s salario.';
                                        INSERT INTO ERROR_CALC_REMUN VALUES
                                                (
                                                (SELECT COUNT(*)+1 FROM ERROR_CALC_REMUN
                                                )
                                                ,
                                                vEmpleado.employee_id,
                                                vMensajeError
                                                );
                                        
                                        vFlagError:=true;
                                END;
                                IF vFlagError=FALSE THEN
                                        vValorBonoPorAnos:=ROUND(vEmpleado.salary*vPorcentajeAnos);
                                END IF;
                        END;
                END IF;
                -- Calculando bono de costo de vida.
                CASE
                WHEN vEmpleado.country_id='US' THEN
                        vPorcentajeCostoVida:=0;
                WHEN vEmpleado.country_id='DE' THEN
                        vPorcentajeCostoVida:=0.8;
                WHEN vEmpleado.country_id='CA' THEN
                        vPorcentajeCostoVida:=0.5;
                ELSE
                        vPorcentajeCostoVida:=0.3;
                END CASE;
                vValorBonoCostoVida:=ROUND(vEmpleado.salary*vPorcentajeCostoVida);
                -- Calculando descuentos.
                vValorDescuentoSeguroSocial:=ROUND((vEmpleado.salary+vEmpleado.valor_comision)*0.062);
                vValorDescuentoSalud       :=ROUND((vEmpleado.salary+vEmpleado.valor_comision)*0.0145);
                -- Calculando totales.
                vTotalHaberes   :=(vEmpleado.salary           +vEmpleado.valor_comision+vValorCargas+vEmpleado.colacion+vEmpleado.movilizacion+vValorBonoPorAnos+vValorBonoCostoVida);
                vTotalDescuentos:=(vValorDescuentoSeguroSocial+vValorDescuentoSalud);
                -- insertando y mostrando informacion.
                INSERT INTO HABER_CALC_MES VALUES
                        (
                                vEmpleado.employee_id   ,
                                vEmpleado.salary        ,
                                vEmpleado.Valor_Comision,
                                vValorCargas            ,
                                vEmpleado.colacion      ,
                                vEmpleado.movilizacion  ,
                                vValorBonoPorAnos       ,
                                vValorBonoCostoVida
                        );
                
                INSERT INTO DESCUENTO_CALC_MES VALUES
                        (
                                vEmpleado.employee_id      ,
                                vValorDescuentoSeguroSocial,
                                vValorDescuentoSalud
                        );
                
                INSERT INTO TOTAL_CALC_MES VALUES
                        (
                                vEmpleado.employee_id,
                                vTotalHaberes        ,
                                vTotalDescuentos     ,
                                (vTotalHaberes-vTotalDescuentos)
                        );
                
                dbms_output.put_line('| '
                ||lpad(vEmpleado.employee_id,11)
                ||' | '
                ||lpad(vEmpleado.salary,13)
                ||' | '
                ||lpad(vEmpleado.Valor_Comision,9)
                ||' | '
                ||lpad(vValorCargas,16)
                ||' | '
                ||lpad(vEmpleado.Colacion,14)
                ||' | '
                ||lpad(vEmpleado.Movilizacion,18)
                ||' | '
                ||lpad(vValorBonoPorAnos,15)
                ||' | '
                ||lpad(vValorBonoCostoVida,16)
                ||' |');
                FETCH vCurEmpleados INTO vEmpleado;
        
        END LOOP;
        CLOSE vCurEmpleados;
        dbms_output.put_line(rpad('-', LENGTH(vTitulo), '-'));
END;