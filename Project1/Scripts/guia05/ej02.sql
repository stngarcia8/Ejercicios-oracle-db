DECLARE
        CURSOR curCursos IS
                SELECT
                        C.cod_curso  ,
                        C.descripcion,
                        COUNT(A.cod_curso) AS CANTIDAD_ALUMNOS
                FROM
                        curso C
                JOIN
                        alumno A
                ON
                        C.cod_curso=A.cod_curso
                GROUP BY
                        c.cod_curso,
                        c.descripcion
                ORDER BY
                        cod_curso;
        
        vCurso curCursos%rowtype;
        vLargoLinea         NUMBER(3) DEFAULT 84;
        vTitulo             VARCHAR2(150);
        vSubrayado          VARCHAR2(150);
        vCantidadDeEspacios NUMBER(2) DEFAULT 0;
        vTituloOrden        VARCHAR2(15);
        vTituloRut          VARCHAR(15);
        vTituloAlumno       VARCHAR2(51);
        vTituloDias         VARCHAR2(60);
        vTituloColumnas     VARCHAR2(250);
        vValorDias          VARCHAR(60);
BEGIN
        vTituloOrden   :='  N°  ';
        vTituloAlumno  :=rpad('ALUMNO',30);
        vTituloRut     :='RUT ALUMNO';
        vTituloDias    :='| LUNES | MARTES | MIERCOLES | JUEVES | VIERNES |';
        vValorDias     :='|   O   |    O   |    O      |    O   |    O    |';
        vTituloColumnas:='| '
        ||vTituloOrden
        ||' | '
        ||vTituloRut
        ||' | '
        ||vTituloAlumno
        ||vTituloDias;
        vLargoLinea:=LENGTH(vTituloColumnas);
        OPEN curCursos;
        FETCH curCursos INTO vCurso;
        
        WHILE curCursos%found
        LOOP
                -- Mostrando encabezado.
                vTitulo:='ASISTENCIA '
                || vCurso.descripcion;
                vSubrayado         :=lpad('-', LENGTH(vTitulo),'-');
                vCantidadDeEspacios:=ROUND((vLargoLinea-LENGTH(vTitulo))/2)+LENGTH(vtitulo);
                vTitulo            :=rpad(lpad(vTitulo, vCantidadDeEspacios, ' '), vLargoLinea);
                vCantidadDeEspacios:=ROUND((vLargoLinea-LENGTH(vSubrayado))/2)+LENGTH(vSubrayado);
                vSubrayado         :=rpad(lpad(vSubrayado, vCantidadDeEspacios), vLargoLinea);
                dbms_output.put_line('');
                dbms_output.put_line(vTitulo);
                dbms_output.put_line(vSubrayado);
                dbms_output.new_line();
                dbms_output.put_line(rpad('-',vLargoLinea,'-'));
                dbms_output.put_line(vTituloColumnas);
                dbms_output.put_line(rpad('-',vLargoLinea,'-'));
                -- Bloque para obtener informacion de alumnos.
                DECLARE
                        CURSOR curAlumnos IS
                                SELECT
                                        rpad(NUMRUT_ALUMNO
                                                ||'-'
                                                ||DVRUT_ALUMNO, 10) AS RUT_ALUMNO,
                                        rpad(UPPER(trim(PNOMBRE_ALUMNO
                                                ||' '
                                                ||SNOMBRE_ALUMNO
                                                ||' '
                                                ||APPAT_ALUMNO
                                                ||' '
                                                ||APMAT_ALUMNO)), 30) AS NOMBRE_ALUMNO
                                FROM
                                        alumno
                                WHERE
                                        cod_curso=vCurso.cod_curso
                                ORDER BY
                                        APPAT_ALUMNO,
                                        APMAT_ALUMNO,
                                        PNOMBRE_ALUMNO;
                        
                        vAlumno curAlumnos%rowtype;
                        vValorOrden VARCHAR2(6);
                        vNroOrden   NUMBER(3) DEFAULT 1;
                BEGIN
                        OPEN curAlumnos;
                        FETCH curAlumnos INTO vAlumno;
                        
                        WHILE curAlumnos%found
                        LOOP
                                -- centrando el orden
                                vValorOrden        :=TRIM(TO_CHAR(vNroOrden, '999'));
                                vCantidadDeEspacios:=ROUND((6-LENGTH(vValorOrden))/2)+LENGTH(vValorOrden);
                                vValorOrden        :=rpad(lpad(vValorOrden, vCantidadDeEspacios), 6);
                                dbms_output.put_line('| '
                                ||vValorOrden
                                ||' | '
                                ||vAlumno.RUT_ALUMNO
                                ||' | '
                                ||vAlumno.NOMBRE_ALUMNO
                                ||vValorDias);
                                FETCH curAlumnos INTO vAlumno;
                                
                                vNroOrden:=vNroOrden+1;
                        END LOOP;
                        dbms_output.put_line(rpad('-',vLargoLinea,'-'));
                        dbms_output.put_line('Total alumnos del curso: '
                        ||trim(TO_CHAR(curAlumnos%rowcount, '999')));
                        dbms_output.new_line();
                        dbms_output.new_line();
                        CLOSE curAlumnos;
                END;
                FETCH curCursos INTO vCurso;
        
        END LOOP;
        CLOSE curCursos;
END;