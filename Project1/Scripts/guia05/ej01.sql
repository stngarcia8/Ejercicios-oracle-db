DECLARE
        CURSOR curAlumnos IS
                SELECT
                        al.APPAT_ALUMNO
                                ||' '
                                ||al.PNOMBRE_ALUMNO AS NOMBRE_ALUMNO    ,
                        al.COD_CURSO                                    ,
                        asig.NOMBRE                                     ,
                        TO_CHAR(PROMEDIO_ASIG, '9D9') AS PROMEDIO_ALUMNO,
                        prom.SITUACION_ASIG
                FROM
                        alumno al
                JOIN
                        PROMEDIO_ASIG_ALUMNO prom
                ON
                        Al.cod_alumno=prom.cod_alumno
                JOIN
                        asignatura asig
                ON
                        prom.cod_asignatura=asig.cod_asignatura
                ORDER BY
                        al.APPAT_ALUMNO  ,
                        al.PNOMBRE_ALUMNO,
                        asig.nombre;
        
        vAlumno curAlumnos%rowtype;
        vNroOrden           NUMBER(3) DEFAULT 1;
        vLargoLinea         NUMBER(3) DEFAULT 84;
        vTitulo             VARCHAR2(150);
        vSubrayado          VARCHAR2(150);
        vCantidadDeEspacios NUMBER(2) DEFAULT 0;
        vTituloOrden        VARCHAR2(15);
        vTituloAlumno       VARCHAR2(51);
        vTituloAsignatura   VARCHAR2(30);
        vTituloPromedio     VARCHAR2(10);
        vTituloSituacion    VARCHAR2(25);
        vTituloColumnas     VARCHAR2(250);
        vValorOrden         VARCHAR2(6);
        vValorPromedio      VARCHAR2(8);
        vValorSituacion     VARCHAR2(15);
BEGIN
        -- Mostrando encabezado.
        vTituloOrden     :='Orden';
        vTituloAlumno    :=rpad('Alumno',51);
        vTituloAsignatura:=rpad('Asignatura', 30);
        vTituloPromedio  :='Promedio';
        vTituloSituacion :='Situación';
        vTituloColumnas  :='| '
        ||vTituloOrden
        ||' | '
        ||vTituloAlumno
        ||' | '
        ||vTituloAsignatura
        ||' | '
        ||vTituloPromedio
        ||' | '
        ||vTituloSituacion
        ||' |';
        vLargoLinea        :=LENGTH(vTituloColumnas);
        vTitulo            :='Estado situación de asignaturas por alumno';
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
        OPEN curAlumnos;
        FETCH curAlumnos INTO vAlumno;
        
        WHILE curAlumnos%found
        LOOP
                IF vAlumno.SITUACION_ASIG='A' THEN
                        vValorSituacion:='Aprobado';
                ELSE
                        vValorSituacion:='Reprobado';
                END IF;
                -- centrando el orden y el promedio.
                vValorOrden        :=TRIM(TO_CHAR(vNroOrden, '999'));
                vCantidadDeEspacios:=ROUND((6-LENGTH(vValorOrden))/2)+LENGTH(vValorOrden);
                vValorOrden        :=rpad(lpad(vValorOrden, vCantidadDeEspacios), 6);
                vValorPromedio     :=TRIM(TO_CHAR(vAlumno.PROMEDIO_ALUMNO, '9D9'));
                vCantidadDeEspacios:=ROUND((8-LENGTH(vValorPromedio))/2)+LENGTH(vValorPromedio);
                vValorPromedio     :=rpad(lpad(vValorPromedio, vCantidadDeEspacios), 8);
                dbms_output.put_line('| '
                ||vValorOrden
                ||' | '
                ||rpad(vAlumno.nombre_alumno,51)
                ||' | '
                ||rpad(vAlumno.nombre,30)
                ||' | '
                ||vValorPromedio
                ||' | '
                ||rpad(vValorSituacion,9)
                ||' |');
                FETCH curAlumnos INTO vAlumno;
                
                vNroOrden:=vNroOrden+1;
        END LOOP;
        CLOSE curAlumnos;
        dbms_output.put_line(rpad('-',vLargoLinea,'-'));
END;