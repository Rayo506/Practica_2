import cx_Oracle

username = 'SYSTEM'
password = 'oracle'
host = '192.168.1.108'
port = 1521
service_name = 'FREEPDB1'

dsn_tns = cx_Oracle.makedsn(host, port, service_name=service_name)

def connect_db():
    try:
        conn = cx_Oracle.connect(user=username, password=password, dsn=dsn_tns)
        print("Conexión exitosa a la base de datos.")
        return conn
    except cx_Oracle.DatabaseError as e:
        print("Error a la base de dades:")
        print(e)
        return None

def insert_def_comandes(conn):
    cursor = conn.cursor()
    print("Inserint comanda amb línies vàlides i invàlides per comprovar trigger...")

    linies = [
        (1001, 50),    # vàlida
        (1002, 150),   # invàlida (>100)
        (1003, 30),    # vàlida
    ]

    # Mostrar línies invàlides (unitats > 100)
    invalides = [l for l in linies if l[1] > 100]
    if invalides:
        print("Línies invàlides que seran filtrades pel trigger (unitats > 100):")
        for codi_linia, unitats in invalides:
            print(f" - Línia {codi_linia} amb {unitats} unitats")

    plsql = """
    DECLARE
        v_client_ref ref CLIENT;
        v_prod1_ref ref PRODUCTE;
        v_prod2_ref ref PRODUCTE;
    BEGIN
        SELECT REF(c) INTO v_client_ref FROM CLIENTE_1 c WHERE codi = 1;
        SELECT REF(p) INTO v_prod1_ref FROM PRODUCTES p WHERE codi = 1;
        SELECT REF(p) INTO v_prod2_ref FROM PRODUCTES p WHERE codi = 2;

        INSERT INTO COMANDES VALUES (COMANDA(99, 20250519, v_client_ref,
            Taula_de_linies(
                LINIA(1001, v_prod1_ref, 50),
                LINIA(1002, v_prod2_ref, 150),
                LINIA(1003, v_prod1_ref, 30)
            )
        ));
    END;
    """
    try:
        cursor.execute(plsql)
        conn.commit()
        print("✔ Comanda inserida correctament.")
    except cx_Oracle.DatabaseError as e:
        error_obj, = e.args
        print(f"Error inserint comanda: {error_obj.message}")

def mostrar_linies_comanda(conn, codi_comanda):
    cursor = conn.cursor()
    print(f"\nLínies de la comanda {codi_comanda} (post-trigger):")

    try:
        cursor.execute("""
            SELECT l.codi, l.unitats
            FROM COMANDES c, TABLE(c.taula_linies) l
            WHERE c.codi = :codi
            ORDER BY l.codi
        """, {"codi": codi_comanda})

        rows = cursor.fetchall()
        if rows:
            for r in rows:
                print(f" - Línia {r[0]} amb {r[1]} unitats")
        else:
            print("⚠ La comanda no conté línies (totes potser filtrades pel trigger).")
    except cx_Oracle.DatabaseError as e:
        print(f"Error llegint línies: {e}")

def llegir_logs(conn):
    cursor = conn.cursor()
    print("\nLlegint taula LogsPreus...")
    cursor.execute("""
        SELECT id_log, producte_codi, preu_antic, preu_nou, TO_CHAR(data_modificacio, 'YYYY-MM-DD HH24:MI:SS')
        FROM LogsPreus ORDER BY id_log
    """)
    rows = cursor.fetchall()
    if rows:
        for r in rows:
            print(f"Log {r[0]} - Producte codi {r[1]}: Preu canviat de {r[2]:.2f} a {r[3]:.2f} el {r[4]}")
    else:
        print("No hi ha canvis de preu registrats.")

def main():
    conn = connect_db()
    if not conn:
        return
    try:
        insert_def_comandes(conn)
        mostrar_linies_comanda(conn, 99)
        llegir_logs(conn)
    finally:
        conn.close()
        print("Connexió tancada.")

if __name__ == "__main__":
    main()
