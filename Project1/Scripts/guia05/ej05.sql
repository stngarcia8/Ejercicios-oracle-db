-- creacion de la tabla RESUMEN_ASIG_PROFESOR
CREATE TABLE RESUMEN_ASIG_PROFESOR
        (
                COD_PROFESOR     NUMBER(5) NOT NULL  ,
                COD_ASIGNATURA   NUMBER(4) NOT NULL  ,
                TOTAL_ALUMNOS    NUMBER(3) NOT NULL  ,
                TOTAL_APROBADOS  NUMBER(3) NOT NULL  ,
                TOTAL_REPROBADOS NUMBER(3) NOT NULL  ,
                PORC_APROBADOS   NUMBER(4,1) NOT NULL,
                PORC_REPROBADOS  NUMBER(4,1) NOT NULL
        );

-- Creacion de la tabla DETALLE_ASIG_PROFESOR
CREATE TABLE DETALLE_ASIG_PROFESOR
        (
                COD_PROFESOR       NUMBER(5) NOT NULL  ,
                COD_ASIGNATURA     NUMBER(4) NOT NULL  ,
                cod_curso          NUMBER(5) NOT NULL  ,
                TOT_ALUMNOS_CURSO  NUMBER(3) NOT NULL  ,
                TOT_APROB_CURSO    NUMBER(3) NOT NULL  ,
                TOTAL_REPROB_CURSO NUMBER(3) NOT NULL  ,
                PORC_APROB_CURSO   NUMBER(4,1) NOT NULL,
                PORC_REPROB_CURSO  NUMBER(4,1) NOT NULL,
                CONSTRAINT DETALLE_ASIG_PROFESOR_pk PRIMARY KEY (COD_PROFESOR, COD_ASIGNATURA, cod_curso)
        );

-- 5:
DECLARE
        CURSOR curProfesores IS
                SELECT
                        cod_profesor  ,
                        cod_asignatura,
                        cod_curso
                FROM
                        horario_profesor
                GROUP BY
                        cod_profesor,
                        cod_curso   ,
                        cod_asignatura
                ORDER BY
                        cod_profesor,
                        cod_curso   ,
                        cod_asignatura;
        
        vProfesor curProfesores%rowtype;
        vTitulo        VARCHAR(150);
        vCodProfesor   VARCHAR2(12);
        vCodAsignatura VARCHAR2(14);
        vCodCurso      VARCHAR2(9);
        vCantidadAprobados detalle_asig_profesor.TOT_APROB_CURSO%type;
        vPorcentajeAprobados detalle_asig_profesor.PORC_APROB_CURSO%TYPE;
        vCantidadReprobados detalle_asig_profesor.TOTAL_REPROB_CURSO%TYPE;
        vPorcentajeReprobados detalle_asig_profesor.PORC_REPROB_CURSO%TYPE;
        vTotalAlumnos detalle_asig_profesor.TOT_ALUMNOS_CURSO%type;
BEGIN
        DELETE FROM RESUMEN_ASIG_PROFESOR;
        
        DELETE FROM DETALLE_ASIG_PROFESOR;
        
        vTitulo:='| cod_profesor | cod_asignatura | cod_curso | total_alumnos_curso | total_aprob_curso | total_reprob_curso | porc_aprob_curso | porc_reprob_curso |';
        dbms_output.put_line('Tabla DETALLE_ASIG_PROFESOR');
        dbms_output.put_line(rpad('-', LENGTH(vTitulo),'-'));
        dbms_output.put_line(vTitulo);
        dbms_output.put_line(rpad('-', LENGTH(vTitulo),'-'));
        OPEN curProfesores;
        FETCH curProfesores INTO vProfesor;
        
        WHILE curProfesores%found
        LOOP
                vCodProfesor       :=rpad(vProfesor.cod_profesor,12);
                vCodAsignatura     :=rpad(vProfesor.cod_asignatura,14);
                vCodCurso          :=lpad(vProfesor.cod_curso,9);
                vCantidadAprobados :=0;
                vCantidadReprobados:=0;
                -- buscan los resultados en la tabla promedio_final_alumno.
                DECLARE
                        CURSOR curAsignaturas IS
                                SELECT
                                        pr.COD_ASIGNATURA,
                                        al.cod_curso     ,
                                        pr.SITUACION_ASIG
                                FROM
                                        PROMEDIO_ASIG_ALUMNO pr
                                JOIN
                                        alumno al
                                ON
                                        pr.cod_alumno=al.cod_alumno
                                WHERE
                                        al.cod_curso     =vProfesor.cod_curso
                                AND     pr.cod_asignatura=vProfesor.cod_asignatura
                                ORDER BY
                                        al.cod_curso,
                                        pr.cod_asignatura;
                        
                        vAsignatura curAsignaturas%rowtype;
                BEGIN
                        OPEN curAsignaturas;
                        FETCH curAsignaturas INTO vAsignatura;
                        
                        WHILE curAsignaturas%found
                        LOOP
                                IF vAsignatura.SITUACION_ASIG='A' THEN
                                        vCantidadAprobados:=vCantidadAprobados+1;
                                ELSE
                                        vCantidadReprobados:=vCantidadReprobados+1;
                                END IF;
                                FETCH curAsignaturas INTO vAsignatura;
                        
                        END LOOP;
                        vTotalAlumnos:=curAsignaturas%rowcount;
                        CLOSE curAsignaturas;
                END;
                vPorcentajeAprobados :=(vCantidadAprobados /vTotalAlumnos)*100;
                vPorcentajeReprobados:=(vCantidadReprobados/vTotalAlumnos)*100;
                -- Insertando datos y mostrando resultados.
                INSERT INTO RESUMEN_ASIG_PROFESOR VALUES
                        (
                                vProfesor.cod_profesor  ,
                                vProfesor.cod_asignatura,
                                vTotalAlumnos           ,
                                vCantidadAprobados      ,
                                vCantidadReprobados     ,
                                vPorcentajeAprobados    ,
                                vPorcentajeReprobados
                        );
                
                INSERT INTO DETALLE_ASIG_PROFESOR VALUES
                        (
                                vProfesor.cod_profesor  ,
                                vProfesor.cod_asignatura,
                                vProfesor.cod_curso     ,
                                vTotalAlumnos           ,
                                vCantidadAprobados      ,
                                vCantidadReprobados     ,
                                vPorcentajeAprobados    ,
                                vPorcentajeReprobados
                        );
                
                dbms_output.put_line('| '
                ||vCodProfesor
                ||' | '
                ||vCodAsignatura
                ||' | '
                ||vCodCurso
                ||' | '
                ||lpad(TO_CHAR(vTotalAlumnos, '999'),19)
                ||' | '
                ||lpad(TO_CHAR(vCantidadAprobados,'999'),17)
                ||' | '
                ||lpad(TO_CHAR(vCantidadReprobados,'999'),18)
                ||' | '
                ||lpad(TO_CHAR(vPorcentajeAprobados,'999'),16)
                ||' | '
                ||lpad(TO_CHAR(vPorcentajeReprobados,'999'),17)
                ||' |');
                FETCH curProfesores INTO vProfesor;
        
        END LOOP;
        CLOSE curProfesores;
        dbms_output.put_line(rpad('-', LENGTH(vTitulo),'-'));
        dbms_output.new_line();
        -- Bloque para mostrar el resultado del resumen.
        DECLARE
                CURSOR curResumenes IS
                        SELECT * FROM RESUMEN_ASIG_PROFESOR ORDER BY COD_PROFESOR, COD_ASIGNATURA;
                
                vResumen curResumenes%rowtype;
        BEGIN
                vTitulo:='| cod_profesor | cod_asignatura | total_alumnos_curso | total_aprob_curso | total_reprob_curso | porc_aprob_curso | porc_reprob_curso |';
                dbms_output.put_line('Tabla RESUMEN_ASIG_PROFESOR:');
                dbms_output.put_line(rpad('-', LENGTH(vTitulo),'-'));
                dbms_output.put_line(vTitulo);
                dbms_output.put_line(rpad('-', LENGTH(vTitulo),'-'));
                OPEN curResumenes;
                FETCH curResumenes INTO vResumen;
                
                WHILE curResumenes%found
                LOOP
                        dbms_output.put_line('| '
                        ||lpad(vResumen.cod_profesor,12)
                        ||' | '
                        ||lpad(vResumen.cod_asignatura,14)
                        ||' | '
                        ||lpad(TO_CHAR(vResumen.TOTAL_ALUMNOS, '999'),19)
                        ||' | '
                        ||lpad(TO_CHAR(vResumen.TOTAL_APROBADOS,'999'),17)
                        ||' | '
                        ||lpad(TO_CHAR(vResumen.TOTAL_REPROBADOS,'999'),18)
                        ||' | '
                        ||lpad(TO_CHAR(vResumen.PORC_APROBADOS,'999'),16)
                        ||' | '
                        ||lpad(TO_CHAR(vResumen.PORC_REPROBADOS,'999'),17)
                        ||' |');
                        FETCH curResumenes INTO vResumen;
                
                END LOOP;
                CLOSE curResumenes;
                dbms_output.put_line(rpad('-', LENGTH(vTitulo),'-'));
        END;
END;
--SELECT * FROM DETALLE_ASIG_PROFESOR;
--SELECT * FROM RESUMEN_ASIG_PROFESOR;