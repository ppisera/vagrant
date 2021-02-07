. /vagrant/scripts/install.env

echo "******************************************************************************"
echo "Create environment script." `date`
echo "******************************************************************************"
cat > ${SCRIPTS_DIR}/setEnv.sh <<EOF
# Regular settings.
export TMP=/tmp
export TMPDIR=\$TMP

export ORACLE_HOSTNAME=`hostname`
export ORACLE_UNQNAME=${ORACLE_UNQNAME}
export ORACLE_BASE=${ORACLE_BASE}
export ORACLE_HOME=${ORACLE_HOME}
export ORACLE_SID=${ORACLE_SID}

export PATH=/usr/sbin:/usr/local/bin:\$PATH
export PATH=\$ORACLE_HOME/bin:\$PATH

export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib

export ORA_INVENTORY=${ORA_INVENTORY}

EOF

echo "******************************************************************************"
echo "Add it to the .bash_profile." `date`
echo "******************************************************************************"
echo ". ${SCRIPTS_DIR}/setEnv.sh" >> /home/oracle/.bash_profile


echo "******************************************************************************"
echo "Create start/stop scripts." `date`
echo "******************************************************************************"
. ${SCRIPTS_DIR}/setEnv.sh

cat > ${SCRIPTS_DIR}/start_all.sh <<EOF
#!/bin/bash
. ${SCRIPTS_DIR}/setEnv.sh

export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES

dbstart \$ORACLE_HOME
EOF


cat > ${SCRIPTS_DIR}/stop_all.sh <<EOF
#!/bin/bash
. ${SCRIPTS_DIR}/setEnv.sh

export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES

dbshut \$ORACLE_HOME
EOF


chown -R oracle.oinstall ${SCRIPTS_DIR}
chmod u+x ${SCRIPTS_DIR}/*.sh


echo "******************************************************************************"
echo "Create a listener.ora file if it doesn't already exist." `date`
echo "******************************************************************************"
if [ ! -f ${ORACLE_HOME}/network/admin/listener.ora ]; then
  
  cat > ${ORACLE_HOME}/network/admin/listener.ora <<EOF
LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) 
  ) 
) 
USE_SID_AS_SERVICE_listener=on
INBOUND_CONNECT_TIMEOUT_LISTENER=400
EOF

  cat > ${ORACLE_HOME}/network/admin/tnsnames.ora <<EOF
LISTENER = (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
${ORACLE_SID}= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = ${ORACLE_SID})
  )
)
${PDB_NAME}= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = ${PDB_NAME})
  )
)
EOF

  cat > ${ORACLE_HOME}/network/admin/sqlnet.ora <<EOF
SQLNET.INBOUND_CONNECT_TIMEOUT=400
EOF

fi


echo "******************************************************************************"
echo "Check if database already exists." `date`
echo "******************************************************************************"
if [ ! -d ${DATA_DIR}/${ORACLE_SID^^} ]; then

  echo "******************************************************************************"
  echo "The database files don't exist, so create a new database." `date`
  echo "******************************************************************************"
  lsnrctl start

  dbca -silent -createDatabase                                                 \
    -templateName General_Purpose.dbc                                          \
    -gdbname ${ORACLE_SID} -sid ${ORACLE_SID} -responseFile NO_VALUE           \
    -characterSet AL32UTF8                                                     \
    -sysPassword ${SYS_PASSWORD}                                               \
    -systemPassword ${SYS_PASSWORD}                                            \
    -createAsContainerDatabase true                                            \
    -numberOfPDBs 1                                                            \
    -pdbName ${PDB_NAME}                                                       \
    -pdbAdminPassword ${PDB_PASSWORD}                                          \
    -databaseType MULTIPURPOSE                                                 \
    -memoryMgmtType auto_sga                                                   \
    -totalMemory 1536                                                          \
    -storageType FS                                                            \
    -datafileDestination "${DATA_DIR}"                                         \
    -redoLogFileSize 50                                                        \
    -emConfiguration NONE                                                      \
    -ignorePreReqs

  echo "******************************************************************************"
  echo "Set the PDB to auto-start." `date`
  echo "******************************************************************************"
  sqlplus / as sysdba <<EOF
alter system set db_create_file_dest='${DATA_DIR}';
alter pluggable database ${PDB_NAME} save state;
alter system set local_listener='LISTENER';
exit;
EOF


fi
