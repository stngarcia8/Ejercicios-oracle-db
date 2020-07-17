-- Creando la tabla bonos del profesor
CREATE TABLE BONO_PROFESOR
        (
                COD_PROFESOR     NUMBER(5) NOT NULL,
                HORAS_ASIG_12    NUMBER(2)         ,
                HORAS_OTRAS_ASIG NUMBER(2)         ,
                MONTO_BONO       NUMBER(6) NOT NULL,
                CONSTRAINT bono_profesor_pk PRIMARY KEY (cod_profesor)
        );

--
DECLARE
        CURSOR curProfesores IS
                SELECT * FROM profesor ORDER BY cod_profesor;
        
        vProfesor curProfesores%rowtype;
        vSuma12 bono_profesor.HORAS_ASIG_12%TYPE;
        vSumaOtros bono_profesor.HORAS_OTRAS_ASIG%TYPE;
        vPorcentajeBono NUMBER(4,2);
        vValorBono bono_profesor.MONTO_BONO%TYPE;
        vCodAsignaturas VARCHAR2(100);
BEGIN
        -- limpiando tabla bono_profesor.
        DELETE FROM bono_profesor;
        
        dbms_output.put_line('cod_profesor | horas_asig_12 | horas_asig_otros | monto_bono |');
        OPEN curProfesores;
        FETCH curProfesores INTO vProfesor;
        
        WHILE curProfesores%found
        LOOP
                vSuma12        :=0;
                vSumaOtros     :=0;
                vCodAsignaturas:='';
                vPorcentajeBono:=0;
                vValorBono     :=0;
                -- Bloque para calculo del bono
                DECLARE
                        CURSOR curAsignaturas IS
                                SELECT
                                        h.cod_curso     ,
                                        h.cod_asignatura,
                                        h.cod_profesor  ,
                                        a.HORAS_SEMANALES
                                FROM
                                        asignatura a
                                JOIN
                                        horario_profesor h
                                ON
                                        a.cod_asignatura=h.cod_asignatura
                                WHERE
                                        h.cod_profesor=vProfesor.cod_profesor
                                GROUP BY
                                        h.cod_curso     ,
                                        h.cod_asignatura,
                                        h.cod_profesor  ,
                                        A.HORAS_SEMANALES
                                ORDER BY
                                        h.cod_profesor,
                                        h.cod_asignatura;
                        
                        vAsignatura curAsignaturas%rowtype;
                BEGIN
                        OPEN curAsignaturas;
                        FETCH curAsignaturas INTO vAsignatura;
                        
                        WHILE curAsignaturas%found
                        LOOP
                                vCodAsignaturas:=vCodAsignaturas
                                ||SUBSTR(vAsignatura.cod_asignatura,-1,1);
                                vSuma12   :=vSuma12   +vAsignatura.HORAS_SEMANALES;
                                vSumaOtros:=vSumaOtros+vAsignatura.HORAS_SEMANALES;
                                FETCH curAsignaturas INTO vAsignatura;
                        
                        END LOOP;
                        CLOSE curAsignaturas;
                        -- Verificando que asignaturas tiene.
                        CASE
                                -- Si el docente dicta asignaturas cuyo código finaliza con 1 y/o 2
                        WHEN instr(vCodAsignaturas,'1')>0 OR instr(vCodAsignaturas,'2')>0 THEN
                                vSumaOtros:=NULL;
                                -- si su total de horas semanales de clases es mayor o igual a 20
                                IF vSuma12>=20 THEN
                                        vPorcentajeBono:=0.5;
                                ELSE
                                        -- si su total de horas semanales de clases es menor a 20
                                        vPorcentajeBono:=0.3;
                                END IF;
                        ELSE
                                -- Si el docente no dicta asignaturas cuyo código finaliza con 1 ó 2
                                vSuma12:=NULL;
                                CASE
                                        -- su total de horas semanales de clases es mayor o igual a 15
                                WHEN vSumaOtros>=15 THEN
                                        vPorcentajeBono:=0.2;
                                        -- si su total de horas semanales de clases es menor a 15 y mayor o igual a 8
                                WHEN vSumaOtros>=8 AND vSumaOtros<15 THEN
                                        vPorcentajeBono:=0.15;
                                        -- si su total de horas semanales de clases es menor a 8
                                WHEN vSumaOtros<8 THEN
                                        vPorcentajeBono:=0.1;
                                ELSE
                                        -- en caso de no cumplir ninguna el porcentaje de bono queda en cero.
                                        vPorcentajeBono:=0;
                                END CASE;
                        END CASE;
                        -- calculando el bono, insertando en la tabla bono_profesor  y mostrando los resultados.
                        vValorBono:=ROUND(vProfesor.SUELDO_BASE*vPorcentajeBono);
                        INSERT INTO bono_profesor VALUES
                                (
                                        vProfesor.cod_profesor,
                                        vSuma12               ,
                                        vSumaOtros            ,
                                        vValorBono
                                );
                        
                        dbms_output.put_line(rpad(TO_CHAR(vProfesor.cod_profesor, '999'),12)
                        ||' | '
                        ||NVL(TO_CHAR(vSuma12, '999'),'(null)')
                        ||' | '
                        ||NVL(TO_CHAR(vSumaOtros, '999'),'(null)')
                        ||' | '
                        ||lpad(TO_CHAR(vValorBono, '999999'),10)
                        ||' | ');
                END;
                FETCH curProfesores INTO vProfesor;
        
        END LOOP;
        CLOSE curProfesores;
END;
SELECT * FROM bono_profesor;