#!/bin/sh


while getopts :c:m:t: opt 
do
	case "$opt" in
		c) configfile=$OPTARG;;
		m) mwhome=$OPTARG;;
		t) type=$OPTARG;;
	esac
done

if [ "$type" == "myaccount" ] || [ "$type" == "myservices" ] || [ "$type" == "gmyservices" ]; then
        echo "This script is installing patches for $type"
else
        echo "Please enter one of the patch types as argument to -t:  myaccount, myservices,gmyservices"
        exit 0
fi



source setup_env.sh
setup_env $configfile

source ./faspot_utility.sh
##########################################################################
###### Functions Defined here ###########################################


change_properties(){
key=$1
value=$2
prop_file=$3
echo " Changing $key with $value in file $prop_file"
grep $key $prop_file > /dev/null

if [ "$?" == "0" ]; then
   echo "In modificatins:"
   sed -i "/$key=/ s =.* =$value g" $prop_file
else
   echo "$key=$value" >> $prop_file 
fi
}

update_properties_cloudportal(){
prop_file=$1
sh ./upgrade_properties.sh
echo "--------->"$METERING_WS_PASSWD
function myfunc()
{
    local foo="python /scratch/aime/enc_dec2.py "
    local bar=$1
    local baz=$foo$bar
    local TAS=`eval ${baz}`
    echo $TAS
}
#METERING_WS_PASSWD=$(myfunc "$METERING_WS_PASSWD")
echo "After----->" $METERING_WS_PASSWD
change_properties APPLICATION_SOURCE_PATH $ORACLE_HOME/cloudportal/deploy $prop_file
change_properties MANAGE_SERVICE_HOST $CP_MYSERVICES_WLS_HOST $prop_file
change_properties MANAGEDSERVER_DOMAIN_HOME $DOMAIN_HOME/cpserver $prop_file
change_properties CONTACT_FORUM_URL http://cloud.oracle.com/mycloud/f?p=service:forums:0 $prop_file
change_properties WEBSITE_FRIENDLY_URL_SUPPORT no $prop_file
change_properties metering_ws_host $METERING_WLS_ADMIN_HOST $prop_file
change_properties metering_ws_port $METERING_PORT $prop_file
change_properties metering_ws_protocol http $prop_file
change_properties metering_ws_user $METERING_WS_USER $prop_file
change_properties metering_ws_pwd $METERING_WS_PASSWD $prop_file
}

update_properties_gcloudportal(){
prop_file=$1
sh ./upgrade_gproperties.sh
change_properties metering_ws_host $METERING_WLS_ADMIN_HOST $prop_file
change_properties metering_ws_port $METERING_PORT $prop_file
change_properties metering_ws_protocol http $prop_file
change_properties metering_ws_user $METERING_WS_USER $prop_file
change_properties metering_ws_pwd $METERING_WS_PASSWD $prop_file
}

#update_properties_cloudportal_new () {
#. $configfile
#}



#############################################################################################################
################################ Main Flow Starts from here 
############################################

OPATCH_SHIPHOME=$PATCH_SHIPHOMES/c9infra_14.1.0.0.0/cloudportal/c9
file=$OPATCH_SHIPHOME/cloudportal_15*


WLS_HOME=$MW_HOME/wlserver_10.3
OPATCH_HOME=$WORK_DIR/cloud_portal_patches_unzips
create_dir  $OPATCH_HOME

#log_entry "***************** Zip filename is $file *******************"
#unzip -o -q $file -d  $OPATCH_HOME
#dir=$(find $OPATCH_HOME/ -mindepth 1 -maxdepth 1 -type d)
#log_entry "cd ed into $dir directory to apply the patch at $file"
#pushd .
#cd $MW_HOME/jrockit*
#JAVA_HOME=$PWD
#popd
#pushd $dir
export ORACLE_HOME=$MW_HOME/Oracle_CloudPortal1
export METERING_WS_USER=OCLOUD9_CLOUDUI_APPID
echo "Checking password" $OCLOUD9_CLOUDUI_APPID_PWD
export METERING_WS_PASSWD=$OCLOUD9_CLOUDUI_APPID_PWD
#(echo Y)|$ORACLE_HOME/OPatch/opatch apply -jre $JAVA_HOME 
#if [ $? -ne 0 ]; then
#	log_entry "Failed to apply patch $file"
#fi
#popd
flag=0
pushd $ORACLE_HOME/cloudportal/scripts/
cloudportal_properties=$ORACLE_HOME/cloudportal/scripts/config/cloudportal_install.properties
cloudportal_gproperties=$ORACLE_HOME/cloudportal/scripts/config/gmyservices_install.properties
case $type in

                "myaccount")  
                               export LD_LIBRARY_PATH=$ORACLE_HOME/lib
                               sh ./upgrade_config_database.sh -t MYACCOUNT
                               if [ $? -ne 0 ]; then
                                      flag=1
                               fi

                               echo " Exit status of upgrade_config_database.sh is $? "
                               update_properties_cloudportal $cloudportal_properties
     	                       sh ./upgrade_myaccount.sh
              		       if [ $? -ne 0 ]; then
  				      flag=1
		               fi 
                               echo " Exit status of ./upgrade_myaccount.sh is $? "
                               ;;
                "myservices") 
                               export LD_LIBRARY_PATH=$ORACLE_HOME/lib
                               sh ./upgrade_config_database.sh -t MYSERVICES
    			       if [ $? -ne 0 ]; then
                                      flag=1
                               fi

			       echo " Exit status of upgrade_config_database.sh is $? "
                               update_properties_cloudportal $cloudportal_properties
                               sh ./upgrade_myservices.sh
                               if [ $? -ne 0 ]; then
                                      flag=1
                               fi

                               echo " Exit status of ./upgrade_myservices.sh is $? "
                               ;;
                "gmyservices") export ORACLE_HOME=/u01/app/fmw/rcuHome
                               export LD_LIBRARY_PATH=$ORACLE_HOME/lib
                               sh ./upgrade_config_database.sh -t GMYSERVICES
                               update_properties_gcloudportal $cloudportal_gproperties
                               sh ./upgrade_gmyservices.sh
                               ;;
                 *) log_entry "Wrong Type $type " ;;
esac

if [ $flag -ne 0 ]; then
        exit 1
fi

popd 

