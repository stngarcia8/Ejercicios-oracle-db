DECLARE
        CURSOR vCurEmpleados IS
                SELECT employee_id, salary FROM employees ORDER BY employee_id;
        
        vEmpleado vCurEmpleados%rowtype;
        vTitulo    VARCHAR2(150);
        vFlagError BOOLEAN DEFAULT FALSE;
        vPorcentajeAumento rango_aumento.porc_aumento%TYPE;
        vAumento employees.salary%TYPE;
        vSalarioAumentado employees.salary%type;
BEGIN
        -- Limpiando tablas.
        DELETE FROM aumento_salario;
        
        DELETE FROM ERRORES_AUMENTO_SALARIOS;
        
        -- Encabezados.
        vTitulo:='| id_empleado | Salario | Aumento | salario_aumentado |';
        dbms_output.put_line('Tabla: aumento_salario');
        dbms_output.put_line(rpad('-', LENGTH(vTitulo),'-'));
        dbms_output.put_line(vTitulo);
        dbms_output.put_line(rpad('-', LENGTH(vTitulo),'-'));
        OPEN vCurEmpleados;
        FETCH vCurEmpleados INTO vEmpleado;
        
        WHILE vCurEmpleados%found
        LOOP
                -- Limpiando variables.
                vSalarioAumentado :=0;
                vAumento          :=0;
                vPorcentajeAumento:=0;
                -- Atrapando los salarios que no esten en el rango.
                vFlagError:=FALSE;
                DECLARE
                        vMensajeError VARCHAR2(100) DEFAULT '';
                BEGIN
                        SELECT
                                porc_aumento
                        INTO    vPorcentajeAumento
                        FROM
                                rango_aumento
                        WHERE
                                vEmpleado.salary BETWEEN salario_inferior AND     salario_superior;
                
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                        vMensajeError:='salario '
                        ||trim(TO_CHAR(vEmpleado.salary, '999999'))
                        ||' no existe entre los rangos de la tabla RANGO_AUMENTO.';
                        vFlagError:=TRUE;
                        INSERT INTO ERRORES_AUMENTO_SALARIOS VALUES
                                (
                                        vEmpleado.employee_id,
                                        vMensajeError
                                );
                
                END;
                -- Calculando aumentos.
                IF vFlagError=FALSE THEN
                        vAumento         :=ROUND(vEmpleado.salary*vPorcentajeAumento);
                        vSalarioAumentado:=(vEmpleado.salary     +vAumento);
                        INSERT INTO aumento_salario VALUES
                                (
                                        vEmpleado.employee_id,
                                        vEmpleado.salary     ,
                                        vAumento             ,
                                        vSalarioAumentado
                                );
                        
                        dbms_output.put_line('| '
                        ||lpad(vEmpleado.employee_id,11)
                        ||' | '
                        ||lpad(TO_CHAR(vEmpleado.salary,'999999'),7)
                        ||' | '
                        ||lpad(TO_CHAR(vAumento, '999999'),7)
                        ||' | '
                        ||lpad(TO_CHAR(vSalarioAumentado,'999999'),17)
                        ||' |');
                END IF;
                FETCH vCurEmpleados INTO vEmpleado;
        
        END LOOP;
        CLOSE vCurEmpleados;
        dbms_output.put_line(rpad('-',LENGTH(vTitulo),'-'));
        dbms_output.new_line();
        -- Mostrando los errores.
        DECLARE
                CURSOR vCurErrores IS
                        SELECT * FROM ERRORES_AUMENTO_SALARIOS ORDER BY id_empleado;
                
                vError vCurErrores%rowtype;
        BEGIN
                -- Encabezados.
                vTitulo:='| id_empleado | '
                ||rpad('Mensaje',100)
                ||' |';
                dbms_output.put_line('Tabla: ERRORES_AUMENTO_SALARIOS');
                dbms_output.put_line(rpad('-', LENGTH(vTitulo),'-'));
                dbms_output.put_line(vTitulo);
                dbms_output.put_line(rpad('-', LENGTH(vTitulo),'-'));
                OPEN vCurErrores;
                FETCH vCurErrores INTO vError;
                
                WHILE vCurErrores%found
                LOOP
                        dbms_output.put_line('| '
                        ||lpad(vError.id_empleado,11)
                        ||' | '
                        ||rpad(vError.mensaje,100)
                        ||' |');
                        FETCH vCurErrores INTO vError;
                
                END LOOP;
                CLOSE vCurErrores;
                dbms_output.put_line(rpad('-', LENGTH(vTitulo),'-'));
        END;
END;