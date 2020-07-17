-- Bloque para procesar los alumnos.
DECLARE
        CURSOR  curAlumnos IS
                SELECT * FROM alumno;
        
        vAprobadas   NUMBER(3) DEFAULT 0;
        vReprobadas  NUMBER(3) DEFAULT 0;
        vCAprobadas  VARCHAR(10);
        vcReprobadas VARCHAR2(10);
        vCantNotas   NUMBER(3);
        vPromedio promedio_asig_alumno.PROMEDIO_ASIG%TYPE;
        vSituacion promedio_asig_alumno.SITUACION_ASIG%TYPE;
        vBecado alumno.BECADO%TYPE;
        vFlagBeca NUMBER(1);
        vAux      VARCHAR(10);

BEGIN
        DELETE FROM PROMEDIO_FINAL_ALUMNO;
        
        dbms_output.new_line();
        dbms_output.put_line('cod_alumno | cod_curso | nota_final | situacion_final | becado |');
        FOR vAlumno IN curAlumnos LOOP
                -- Limpiando variables.
                vAprobadas  :=0;
                vCAprobadas :='';
                vReprobadas :=0;
                vCReprobadas:='';
                vCantNotas  :=0;
                vSituacion  :='-';
                vBecado     :='-';
                vFlagBeca   :=0;
                vAux        :='';

                --Bloque para procesamiento de las notas.
                DECLARE
                        CURSOR curNotas IS
                                SELECT *
                                FROM PROMEDIO_ASIG_ALUMNO
                                WHERE cod_alumno=(vAlumno.cod_alumno)
                                ORDER BY cod_asignatura;
                        
                        vNota curNotas%rowtype;

                BEGIN
                        OPEN curNotas;
                        FETCH curNotas INTO vNota;
                        WHILE curNotas%found LOOP
                                IF vNota.SITUACION_ASIG='A' THEN
                                        vAprobadas :=vAprobadas+1;
                                        vCAprobadas:=vCAprobadas||SUBSTR(vnota.cod_asignatura,-1,1);
                                ELSE
                                        vReprobadas :=vReprobadas+1;
                                        vCReprobadas:=vCReprobadas||SUBSTR(vNota.cod_asignatura,-1,1);
                                END IF;
                                --dbms_output.put_line(vCAprobadas||'   ---  '||vCReprobadas);
                                FETCH   curNotas INTO    vNota;
                        END LOOP;
                        vCantNotas:=curNotas%rowcount;
                        CLOSE curNotas;

                        -- Calculando promedio.
                        SELECT ROUND(AVG(PROMEDIO_ASIG),2)
                        INTO    vPromedio
                        FROM PROMEDIO_ASIG_ALUMNO
                        WHERE cod_alumno=vAlumno.cod_alumno;
                        
                        -- Verificando reglas de negocio.
                        CASE
                                -- Si el alumno aprobó todas las asignaturas...
                        WHEN vAprobadas=vCantNotas THEN
                                vSituacion:='A';
                                vFlagBeca :=1;

                                -- Si el alumno reprobó todas sus asignaturas...
                        WHEN vReprobadas=vCantNotas THEN
                                vSituacion:='R';
                                vFlagBeca :=0;

                                -- Si el alumno reprobó ambas asignaturas cuyo código finaliza en 1 ó 2...
                        WHEN instr(vCReprobadas,'12')>0 THEN
                                vSituacion:='R';
                                vFlagBeca :=0;

                                -- Si el alumno reprobó una de las asignaturas cuyo código finaliza en 1 ó 2...
                        WHEN (instr(vCReprobadas,'1') >0 OR instr(vCReprobadas,'2')>0) AND instr(vCReprobadas,'12')=0 THEN

                                -- , pero aprobó todas las otras asignaturas y el promedio de todas las notas es superior a 5...
                                IF vPromedio>5 THEN
                                        vSituacion:='A';
                                ELSE
                                        vSituacion:='R';
                                END IF;
                                vAux:=vCReprobadas;
                                IF instr(vAux,'1')>0 THEN
                                        vAux:=REPLACE(vAux,'1','');
                                END IF;
                                IF instr(vAux,'2')>0 THEN
                                        vAux:=REPLACE(vAux,'2','');
                                END IF;
                                IF LENGTH(vAux)=1 THEN

                                        -- además reprobó una de las otras asignaturas y el promedio de todas las notas es superior a 4,8
                                        IF vPromedio >4.8 THEN
                                                vSituacion:='A';
                                        ELSE
                                                vSituacion:='R';
                                        END IF;
                                ELSE

                                        -- además reprobó más de una de las otras asignaturas y el promedio de todas las notas es superior a 5...
                                        IF vPromedio>5 THEN
                                                vSituacion:='A';
                                        ELSE
                                                vSituacion:='R';
                                        END IF;
                                END IF;
                                vFlagBeca:=0;

                                -- Si el alumno aprobó las dos asignaturas cuyo código finaliza en 1 ó 2...
                        WHEN instr(vCAprobadas,'12')>0 THEN

                                -- pero reprobó más de una o todas las otras asignaturas y el promedio de todas las notas es superior a 5
                                IF LENGTH(vCReprobadas)>1 THEN
                                        IF vPromedio   >5 THEN
                                                vSituacion:='A';
                                                vFlagBeca :=1;
                                        ELSE
                                                vSituacion:='R';
                                                vFlagBeca :=0;
                                        END IF;
                                ELSE

                                        -- además aprobó dos de las otras asignaturas y el promedio de todas las notas es superior a 5,5...
                                        IF vPromedio>5.5 THEN
                                                vSituacion:='A';
                                                vFlagBeca :=1;
                                        ELSE
                                                vSituacion:='R';
                                                vFlagBeca :=0;
                                        END IF;
                                END IF;

                                -- Si hay algun problema, la situacion mostrara un asterisco.
                        ELSE
                                vSituacion:='*';
                                vFlagBeca :=0;
                        END CASE ;

                        -- Verificando si perdio o mantiene la beca.
                        IF vAlumno.becado IS NOT NULL AND vFlagBeca=1 THEN
                                vBecado:='S';
                        ELSE
                                vBecado:=NULL;
                        END IF;

                        -- Insertando y actualizando datos.
                        INSERT INTO PROMEDIO_FINAL_ALUMNO VALUES(vAlumno.cod_alumno, vAlumno.cod_curso , vPromedio         , vSituacion);
                        UPDATE alumno SET BECADO=vBecado WHERE cod_alumno=vAlumno.cod_alumno;
                        
                        -- Mostrando resultados de las notas.
                        dbms_output.put_line(rpad(TO_CHAR(vAlumno.cod_alumno,'9999'),10)||' | '||rpad(TO_CHAR(vAlumno.cod_curso, '9999'),9)
                        ||' | '||rpad(TO_CHAR(vPromedio, '9D9'),10)
                        ||' | '||rpad(vsituacion,15)||' | '||rpad(NVL(vBecado,'(null)'),6)
                        ||' |');
                END;
        END LOOP;

        -- Mostrando los resultado de los alumnos.
        dbms_output.new_line();
        dbms_output.put_line(rpad('Cod.Alumno',12)||' | '||rpad('Nombre alumno',50)||' | '||rpad('Becado',10));
        FOR vAlumno IN curAlumnos LOOP
                dbms_output.put_line(rpad(TO_CHAR(vAlumno.cod_alumno, '9999'),12)||' | '||
                rpad(vAlumno.PNOMBRE_ALUMNO||' '||vAlumno.APPAT_ALUMNO,50)||' | '
                ||rpad(NVL(vAlumno.BECADO, '(null)'),10));
        END LOOP;
END;
