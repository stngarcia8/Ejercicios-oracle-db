-- Creacion de la tabla de errores para el ejercicio 01 de la guia 06
CREATE TABLE erroresEj0601
        (
                SEC_ERROR   NUMBER(5) NOT NULL    ,
                ID_EMPLEADO NUMBER(5) NOT NULL    ,
                mensaje     VARCHAR2(100) NOT NULL,
                CONSTRAINT erroresEj0601_pk PRIMARY KEY (SEC_ERROR)
        );

-- 1:
DECLARE
        vEmpleado employees%rowtype;
BEGIN
        -- Ingresando informacion del nuevo empleado.
        vEmpleado.EMPLOYEE_ID   :=to_number(TO_CHAR('&ID_Empleado','999999'));
        vEmpleado.FIRST_NAME    :=InitCap(TRIM(rpad('&nombre_empleado',20)));
        vEmpleado.LAST_NAME     :=initcap(TRIM(rpad('&Apellidos_empleado',25)));
        vEmpleado.EMAIL         :=TRIM(rpad('&Email',25));
        vEmpleado.PHONE_NUMBER  :=TRIM(rpad('&Numero_telefonico',20));
        vEmpleado.HIRE_DATE     :=to_date('&Fecha_contrato','dd/MM/yy');
        vEmpleado.JOB_ID        :=TRIM(rpad('&Id_del_empleo',10));
        vEmpleado.salary        :=to_number(TO_CHAR('&Salario', '99999D99'));
        vEmpleado.COMMISSION_PCT:=to_number(to_number(TO_CHAR('&Porcentaje_comision','99')))/100;
        vEmpleado.MANAGER_ID    :=to_number(TO_CHAR('&Id_manager','99999999'));
        vEmpleado.DEPARTMENT_ID :=to_number(TO_CHAR('&Id_del_departamento','9999'));
        -- Insertando informacion de empleado.
        DECLARE
                vExceptionSinClaveForanea EXCEPTION;
                PRAGMA exception_init(vExceptionSinClaveForanea,-02291);
                vExceptionCampoNulo EXCEPTION;
                PRAGMA exception_init(vExceptionCampoNulo,-1400);
                vExceptionSueldoMayor24Mil EXCEPTION;
                vIdError erroresEj0601.SEC_ERROR%TYPE;
                vMensajeError erroresEj0601.mensaje%TYPE;
                vFlagError BOOLEAN DEFAULT FALSE;
        BEGIN
                -- Capturando errores.
                BEGIN
                        SELECT COUNT(SEC_ERROR)+1 INTO vIdError FROM erroresEj0601;
                        
                        INSERT INTO employees VALUES
                                (
                                        vEmpleado.EMPLOYEE_ID   ,
                                        vEmpleado.FIRST_NAME    ,
                                        vEmpleado.LAST_NAME     ,
                                        vEmpleado.EMAIL         ,
                                        vEmpleado.PHONE_NUMBER  ,
                                        vEmpleado.HIRE_DATE     ,
                                        vEmpleado.JOB_ID        ,
                                        vEmpleado.SALARY        ,
                                        vEmpleado.COMMISSION_PCT,
                                        vEmpleado.MANAGER_ID    ,
                                        vEmpleado.DEPARTMENT_ID
                                );
                        
                        IF vEmpleado.SALARY>24000 THEN
                                RAISE vExceptionSueldoMayor24Mil;
                        END IF;
                EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                        vMensajeError:='Se está insertando un valor de Clave primaria que ya existe.';
                        vFlagError   :=TRUE;
                WHEN vExceptionSinClaveForanea THEN
                        vMensajeError:='Se está insertando un valor de Clave Foránea que no existe.';
                        vFlagError   :=TRUE;
                WHEN vExceptionCampoNulo THEN
                        vMensajeError:='Se está insertando un valor nulo en una columna obligatoria.';
                        vFlagError   :=TRUE;
                WHEN vExceptionSueldoMayor24Mil THEN
                        vMensajeError:='Se está insertando un salario mayor a 24000.';
                        vFlagError   :=true;
                WHEN OTHERS THEN
                        dbms_output.put_line('Código de error no controlado: '
                        ||SQLCODE);
                        dbms_output.put_line(sqlerrm);
                END;
                IF vFlagError THEN
                        INSERT INTO erroresEj0601 VALUES
                                (
                                        vIdError             ,
                                        vEmpleado.EMPLOYEE_ID,
                                        vMensajeError
                                );
                        
                        dbms_output.put_line('Error log:'
                        ||TO_CHAR(vIdError,'99999')
                        ||' - id empleado:'
                        ||TO_CHAR(vEmpleado.EMPLOYEE_ID,'999999')
                        ||' - '
                        ||vMensajeError);
                ELSE
                        dbms_output.put_line('Empleado '
                        ||trim(vEmpleado.FIRST_NAME)
                        ||' '
                        ||trim(vEmpleado.LAST_NAME)
                        ||' creado correctamente.');
                END IF;
        END;
END;
--select * from erroresEj0601;
--delete from erroresEj0601;