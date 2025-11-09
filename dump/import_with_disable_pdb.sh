#!/bin/bash

USER="TEST_SCHEMA"
PASS="test1234"
PDB_SERVICE="XEPDB1"
SCHEMA="TEST_SCHEMA"
DUMP_FILE="import_data.dmp"
DIRECTORY="DATA_PUMP_DIR"
LOG_FILE="import_log.log"

CONN_STR="${USER}/${PASS}@${PDB_SERVICE}"

echo "PDBに直接接続してインポート実行開始"

# 外部キー・トリガー無効化
# sqlplus -s "$CONN_STR" <<EOF
# WHENEVER SQLERROR EXIT SQL.SQLCODE
# SET HEADING OFF
# SET FEEDBACK OFF
# SET PAGESIZE 0
# SPOOL disable_constraints_triggers.sql

# -- 外部キーを無効化
# SELECT 'ALTER TABLE ' || table_name || ' DISABLE CONSTRAINT ' || constraint_name || ';'
#   FROM user_constraints
#  WHERE constraint_type = 'R';

# -- トリガーを無効化
# SELECT 'ALTER TRIGGER ' || trigger_name || ' DISABLE;'
#   FROM user_triggers;

# SPOOL OFF
# @disable_constraints_triggers.sql
# EXIT;
# EOF

# 再有効化
sqlplus -s "$CONN_STR" <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SPOOL enable_constraints_triggers.sql

SELECT 'ALTER TABLE ' || table_name || ' ENABLE CONSTRAINT ' || constraint_name || ';'
  FROM user_constraints
 WHERE constraint_type = 'R';

SELECT 'ALTER TRIGGER ' || trigger_name || ' ENABLE;'
  FROM user_triggers;

SPOOL OFF

@enable_constraints_triggers.sql
EXIT;
EOF

echo "=== 完了 ==="
