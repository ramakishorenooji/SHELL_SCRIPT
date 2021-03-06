#!/bin/sh

while getopts :c:m: opt
do case "$opt" in
c) configfile=$OPTARG;;
m) mwhome=$OPTARG;;
esac
done

source $PWD/faspot_utility.sh
create_dir $WORK_DIR/cb_nuviaq_patch

PATCH_NUVIAQ=$PATCH_SHIPHOMES/c9infra_14.1.0.0.0/nuviaq/c9/
nuviaqdomainHome=$DOMAIN_HOME/
nuviaqHome=$MW_HOME/nuviaq
nuviaqPropsFile=$nuviaqHome/nuviaq.properties
hostName=$TASDC_DB_HOST
UNZIP='/usr/bin/unzip -oq'
pushd .
cd $MW_HOME/modules/org.apache.ant_*
antHome=$PWD
popd

pushd .
cd $MW_HOME/jrockit*
JAVA_HOME=$PWD
popd



export MW_HOME=$MW_HOME
export ORACLE_HOME=$nuviaqHome
export NUVIAQ_WORK=$nuviaqdomainHome/nuviaq-work
export T_WORK=$nuviaqdomainHome
export ANT_HOME=$antHome
export JAVA_HOME=$JAVA_HOME



# handles post configuration steps after applying the patch
echo "Post configuration steps.."
$antHome/bin/ant -f $nuviaqHome/build.xml -Dinstall.properties=$nuviaqPropsFile patch-domain
if [ $? -ne 0 ]; then
 echo "failed to patch nuviaq domain. Post configuration failed, exiting applying patch .."
 exit 1
fi

$antHome/bin/ant -f $nuviaqHome/build.xml -Dinstall.properties=$nuviaqPropsFile patch-db
if [ $? -ne 0 ]; then
 echo "failed to path nuviaq db. Post configuration failed, exiting applying patch .."
 exit 1
fi

$antHome/bin/ant -f $nuviaqHome/build.xml -Dinstall.properties=$nuviaqPropsFile start-nuviaq
if [ $? -ne 0 ]; then
 echo "failed to restart nuviaq domain. Post configuration failed, exiting applying patch .."
 exit 1
fi

echo "Post configuration steps successfull."

