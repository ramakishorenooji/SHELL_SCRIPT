#!/bin/sh
set -e
while getopts :c:m:r:t: opt
do case "$opt" in
c) configfile=$OPTARG;;
m) mwhome=$OPTARG;;
t) type=$OPTARG;;
esac
done

if [[ $type != "TASC" && $type != "TASDC" ]]; then
  echo "Type of TASC or TASDC must be passed, e.g. -t TASC"
  exit 1
fi

source setup_env.sh
setup_env $configfile

source ./faspot_utility.sh

if [ $mwhome ]; then
  MW_HOME=$mwhome
fi

create_dir $WORK_DIR
log_entry "Middleware Home being used is $MW_HOME"
timestamp=`date +%y-%m-%d_%H-%M-%S`
LOG_FILE=$WORK_DIR/cb_tas_patch_$timestamp.log
echo "Start time: `date`" >> $LOG_FILE

###########################################################
# Functions used defined here
###########################################################
#result=$(myfunc "$DB_ADMIN_PWD $TAS_PWD $DB_NS_PWD $WLS_ADMIN_PWD $NODE_MANAGER_USER_PWD $idm_idstore_pwd $TAS_SERVICE_MANAGER_AUTH_USER_PWD")

set -e 

TAS_HOME=$MW_HOME/Oracle_TAS1
workDir=$WORK_DIR/patches/tas
create_dir $workDir

export ORACLE_HOME=$TAS_HOME
export PATH=$TAS_HOME/OPatch:$PATH

if [ $type = "TASC" ]; then 
DB_ADMIN_PWD=$TASC_DB_SYS_PASSWD
WLS_ADMIN_PWD=$TASC_WLS_ADMIN_PASSWD
TAS_PWD=$TASC_PASSWD
NODE_MANAGER_USER_PWD=$WLS_ADMIN_PWD
TAS_REST_CENTRAL_URL=no_value
IDM_REST_DATACENTER_URL=no_value
else
DB_ADMIN_PWD=$TASDC_DB_SYS_PASSWD
WLS_ADMIN_PWD=$TASDC_WLS_ADMIN_PASSWD
TAS_PWD=$TASDC_PASSWD
NODE_MANAGER_USER_PWD=$WLS_ADMIN_PWD
TAS_REST_CENTRAL_URL=http://${TASC_TRA_VIRTUAL_HOSTNAME}:${TRA_CENTRAL_PORT}
IDM_REST_DATACENTER_URL=http://${IDM_OIM_HOST}:${CPUI_REST_MANAGED_SERVER_PORT}

fi

# This assumes only one *TAS*.zip file and no other patches in $workDir...not as good
# assumption. Needs to be fixed

####################bug 19999322###################
update_config_file() {
key=$1
value=$2
CONFIG_FILE=$3

if [ ${CONFIG_FILE}x == "x" ]; then
  log_entry "Value for key:$key is missing. Please check the properties file for the corresponding value and run again."
  exit 1
fi

sed -i -e "s%$key>.*</$key%$key>$value</$key%" $CONFIG_FILE
}


####################################################
# 14.1 release

export ORACLE_HOME=$DB_HOME
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
log_entry "ORACLE HOME is $ORACLE_HOME"
###################################################
INSTALL_CONFIG_FILE=$TAS_HOME/tas/install_properties.xml
log_entry "Modifying tas central configuration files"

update_config_file  NS_VIRTUAL_HOSTNAME $TASDC_NS_VIRTUAL_HOSTNAME $INSTALL_CONFIG_FILE

if [ ${SEC_MODE}x == "truex" ]; then
    update_config_file NS_PORT $NS_DC_SSL_PORT $INSTALL_CONFIG_FILE
else
    update_config_file NS_PORT $NS_DC_PORT $INSTALL_CONFIG_FILE
fi
if [ "$type" == "TASC" ]; then
      log_entry "Running DCA Tool for upgrade dca "
    ./config_tas_sdi_domain_in_idm.sh -c $configfile -t UPGRADEC 2>&1 | tee -a $MAIN_LOG_FILE
   else
   log_entry "Running DCA Tool for upgrade dca "
   ./config_tas_sdi_domain_in_idm.sh -c $configfile -t UPGRADEDC 2>&1 | tee -a $MAIN_LOG_FILE
fi
###################################################
# 14.1 release

pushd  $TAS_HOME/tas

######################################################################################################################
#log_entry "TAS_RDC_SYNC_AUTH_USER_PWD:   $TAS_RDC_SYNC_AUTH_USER_PWD\n"

#REQ_PWD="Welcome1"
#$TAS_GSI_BRIDGE_PWD = `python /scratch/aime/enc_dec2.py -d MKEdi7skbb4= `

#TAS_RDC_SYNC_AUTH_USER_PWD=MKEdi7skbb4=
#echo "this is the missing password" $TAS_RDC_SYNC_AUTH_USER_PWD

function myfunc()
{
    local foo="python /scratch/aime/enc_dec2.py "
    local bar=$1
    local baz=$foo$bar
    local TAS=`eval ${baz}`
    echo $TAS
}


#log_entry "Checking the value: $TAS_RDC_SYNC_AUTH_USER_PWD $idm_idstore_pwd"
echo "$DB_ADMIN_PWD $TAS_PWD $DB_NS_PWD $WLS_ADMIN_PWD $NODE_MANAGER_USER_PWD $idm_idstore_pwd $TAS_SERVICE_MANAGER_AUTH_USER_PWD"
#result=myfunc "$DB_ADMIN_PWD $TAS_PWD $DB_NS_PWD $WLS_ADMIN_PWD $NODE_MANAGER_USER_PWD $idm_idstore_pwd $TAS_SERVICE_MANAGER_AUTH_USER_PWD"

#result=myfunc ("$DB_ADMIN_PWD $TAS_PWD $DB_NS_PWD $WLS_ADMIN_PWD $NODE_MANAGER_USER_PWD $idm_idstore_pwd $TAS_SERVICE_MANAGER_AUTH_USER_PWD")   # or result=`myfunc`
echo "******* Before : $DB_ADMIN_PWD $TAS_PWD $DB_NS_PWD $WLS_ADMIN_PWD $NODE_MANAGER_USER_PWD  $idm_idstore_pwd $TAS_RDC_SYNC_AUTH_USER_PWD******"
#bade="MKEdi7skbb4="
TASDCresul=$(myfunc "$DB_ADMIN_PWD $TAS_PWD $DB_NS_PWD $WLS_ADMIN_PWD $NODE_MANAGER_USER_PWD  $idm_idstore_pwd $TAS_RDC_SYNC_AUTH_USER_PWD")
echo "******* After : $TASDCresul******"

TASCresul=$(myfunc "$DB_ADMIN_PWD $TAS_PWD $TAS_GSI_BRIDGE_PWD $TPM_JMS_DB_USER_PWD $WLS_ADMIN_PWD $NODE_MANAGER_USER_PWD $IDM_BIND_DN_PWD $TAS_SERVICE_MANAGER_AUTH_USER_PWD $METERING_AUTH_USER_PWD")
#echo "This is result " $result
#echo $TAS_RDC_SYNC_AUTH_USER_PWD
#log_entry "TAS_RDC_SYNC_AUTH_USER_PWD:   $TAS_RDC_SYNC_AUTH_USER_PWD"



if [ "$type" == "TASC" ]; then
          log_entry $LINENO "$DB_ADMIN_PWD $TAS_PWD $TAS_GSI_BRIDGE_PWD $TPM_JMS_DB_USER_PWD $WLS_ADMIN_PWD $NODE_MANAGER_USER_PWD $IDM_BIND_DN_PWD $TAS_SERVICE_MANAGER_AUTH_USER_PWD $METERING_AUTH_USER_PWD | ./patches_4_cloud.pl"
#	 echo $DB_ADMIN_PWD $TAS_PWD $TAS_GSI_BRIDGE_PWD $TPM_JMS_DB_USER_PWD $WLS_ADMIN_PWD $NODE_MANAGER_USER_PWD $IDM_BIND_DN_PWD $TAS_SERVICE_MANAGER_AUTH_USER_PWD $METERING_AUTH_USER_PWD | ./patches_4_cloud.pl
	echo $TASCresul | ./patches_4_cloud.pl

else       
#           log_entry $LINENO "$DB_ADMIN_PWD $TAS_PWD $DB_NS_PWD $WLS_ADMIN_PWD $NODE_MANAGER_USER_PWD  $idm_idstore_pwd $TAS_RDC_SYNC_AUTH_USER_PWD" | ./patches_4_cloud.pl
	    log_entry $LINENO "$TASresul | ./patches_4_cloud.pl"
#	   echo $DB_ADMIN_PWD $TAS_PWD $DB_NS_PWD $WLS_ADMIN_PWD $NODE_MANAGER_USER_PWD $idm_idstore_pwd $TAS_RDC_SYNC_AUTH_USER_PWD | ./patches_4_cloud.pl
	   echo $TASDCresul | ./patches_4_cloud.pl
fi

if [ $? -ne 0 ]; then 
	log_entry "Failed to apply patch $patchFile"
	exit 1
fi

popd
