開業コード修正

tr -d '\r' < import_with_disable_pdb.sh > tmp.sh && mv tmp.sh import_with_disable_pdb.sh
chmod +x import_with_disable_pdb.sh

出力先ファイル
SELECT directory_name, directory_path FROM dba_directories WHERE directory_name='DATA_PUMP_DIR';


CREATE OR REPLACE DIRECTORY DATA_PUMP_DIR AS '/opt/oracle/dpdump';
GRANT READ, WRITE ON DIRECTORY DATA_PUMP_DIR TO SYSTEM;