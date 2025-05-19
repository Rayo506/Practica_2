--Trigger validar_unitats que impedeixi inserir una línia de comanda amb més de 100 unitats.
CREATE OR REPLACE TRIGGER skip_unitats_excedides
  BEFORE INSERT OR UPDATE
    ON COMANDES
  FOR EACH ROW
DECLARE
  v_nova Taula_de_linies := Taula_de_linies();  -- nova coleccio buida
BEGIN
  IF :NEW.taula_linies IS NOT NULL THEN
    -- Recorrem cada element de la coleccio original
    FOR i IN 1 .. :NEW.taula_linies.COUNT LOOP
      IF :NEW.taula_linies(i).unitats <= 100 THEN
        -- Afegim una linia si cumpleix la condicio
        v_nova.EXTEND; -- aÃ±adiomos una nueva fila (null)
        v_nova(v_nova.LAST) := :NEW.taula_linies(i);
      END IF;
    END LOOP;
    -- Reassignem al NEW la coleccio filtrada
    :NEW.taula_linies := v_nova;
  END IF;
END;
/

--Crear una taula LogsPreus(id_log, producte_id, preu_antic, preu_nou, data_modificacio)
CREATE TABLE LogsPreus (
  id_log            NUMBER        PRIMARY KEY,
  producte_codi     NUMBER        NOT NULL
  CONSTRAINT fk_lp_productes REFERENCES PRODUCTES(codi),
  preu_antic        NUMBER(10,2)  NOT NULL,
  preu_nou          NUMBER(10,2)  NOT NULL,
  data_modificacio  DATE          DEFAULT SYSDATE
);
/

--Es para hacer el siguiente valor se vaya sumando la id
CREATE SEQUENCE seq_logspreus
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;
/

--Trigger log_preu_producte que enregistri cada canvi de preu.
CREATE OR REPLACE TRIGGER log_preu_producte
  AFTER UPDATE OF preu
    ON PRODUCTES
  FOR EACH ROW
  WHEN (OLD.preu <> NEW.preu)
BEGIN
  INSERT INTO LogsPreus (
    id_log,
    producte_codi,
    preu_antic,
    preu_nou,
    data_modificacio
  ) VALUES (
    seq_logspreus.NEXTVAL,
    :OLD.codi,
    :OLD.preu,
    :NEW.preu,
    SYSDATE
  );
END;
/