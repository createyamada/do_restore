#!/bin/bash

# ==============================
# 設定項目（適宜修正）
# ==============================
CDB_USER="sys"
CDB_PASS="oracle"
CDB_SID="XE"         # Oracle XEでは SID は「XE」
PDB_NAME="XEPDB1"
SCHEMA="TEST_SCHEMA"
DUMP_FILE="import_data.dmp"
DIRECTORY="DATA_PUMP_DIR"
LOG_FILE="import_log.log"

# ==============================
# PDB接続文字列作成
# ==============================
CONN_STR="${CDB_USER}/${CDB_PASS}@${CDB_SID} AS SYSDBA"

echo "=========================================="
echo " PDB環境でのData Pumpインポート実行開始"
echo " ターゲットPDB: ${PDB_NAME}"
echo " スキーマ: ${SCHEMA}"
echo "=========================================="

# ==============================
# 外部キー・トリガー無効化
# ==============================
echo "外部キーとトリガーを無効化中..."

sqlplus -s "$CONN_STR" <<EOF
ALTER SESSION SET CONTAINER=${PDB_NAME};
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SPOOL disable_constraints_triggers.sql

-- 外部キーを無効化
SELECT 'ALTER TABLE ' || owner || '.' || table_name || ' DISABLE CONSTRAINT ' || constraint_name || ';'
  FROM all_constraints
 WHERE constraint_type = 'R'
   AND owner = UPPER('${SCHEMA}');

-- トリガーを無効化
SELECT 'ALTER TRIGGER ' || owner || '.' || trigger_name || ' DISABLE;'
  FROM all_triggers
 WHERE owner = UPPER('${SCHEMA}');

SPOOL OFF

@disable_constraints_triggers.sql
EXIT;
EOF

echo "無効化完了。"

# ==============================
# データインポート実行（PDBコンテナ上で）
# ==============================
echo "Data Pumpインポート開始..."

impdp \"/ as sysdba\" \
    directory=${DIRECTORY} \
    dumpfile=${DUMP_FILE} \
    logfile=${LOG_FILE} \
    schemas=${SCHEMA} \
    table_exists_action=replace \
    transform=disable_archive_logging:y \
    cluster=n \
    remap_schema=${SCHEMA}:${SCHEMA} \
    pdb=${PDB_NAME}

echo "インポート完了。"

# ==============================
# 外部キー・トリガー再有効化
# ==============================
echo "外部キーとトリガーを再有効化中..."

sqlplus -s "$CONN_STR" <<EOF
ALTER SESSION SET CONTAINER=${PDB_NAME};
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SPOOL enable_constraints_triggers.sql

-- 外部キーを有効化
SELECT 'ALTER TABLE ' || owner || '.' || table_name || ' ENABLE CONSTRAINT ' || constraint_name || ';'
  FROM all_constraints
 WHERE constraint_type = 'R'
   AND owner = UPPER('${SCHEMA}');

-- トリガーを有効化
SELECT 'ALTER TRIGGER ' || owner || '.' || trigger_name || ' ENABLE;'
  FROM all_triggers
 WHERE owner = UPPER('${SCHEMA}');

SPOOL OFF

@enable_constraints_triggers.sql
EXIT;
EOF

echo "再有効化完了。"

echo "=== 全処理正常終了 ==="
