#!/bin/sh  


unzipRCU()
{

          
	# Location for  RCU zip
         RCU_SHIPHOME_FILE=$SHIPHOMES/soa/shiphome/RCUINTEGRATION_11.1.1.7.0_LINUX.X64_RELEASE

	if [ -f $RCU_SHIPHOME_FILE ]; then
        	echo "File $RCU_SHIPHOME_FILE exists"
    	else
        	echo "File $RCU_SHIPHOME_FILE does NOT exists"
        	exit 1
    	fi
	
	RCU_ZIP_FILENAME=`head -1 $RCU_SHIPHOME_FILE`

        # Unzipping RCU if required
        if [ -d $DB_HOME ]; then
                echo "RCU has already been unzipped to $DB_HOME "
        else
	        echo "Unzipping RCU from $RCU_ZIP_FILENAME to $DB_HOME for using sqlplus ..."
         	unzip -o -q $RCU_ZIP_FILENAME -d $DB_HOME 
        fi
}

