#!/bin/bash

: ${HONEYCOMB_HOME?"Need to set HONEYCOMB_HOME environmental variable to the top of the project."}
command -v mvn >/dev/null 2>&1 || { echo >&2 "mvn is required to run $0."; exit 1; }

if [ ! -z "$HONEYCOMB_LIB" ]
then
  honeycomb_lib=$HONEYCOMB_LIB
else
  honeycomb_lib=/usr/local/lib/honeycomb
fi

source $HONEYCOMB_HOME/bin/constants.sh
echo -e "Running Maven build script\n"

testOption=$1
mvnTestMode="-DskipIntTests"

if [ -n "$testOption" ]
then
    case "$testOption" in
        none)
            echo -e "Disabling unit and integration tests\n"
            mvnTestMode="-DskipTests"
            ;;
        all)
            echo -e "Enabling unit and integration tests\n"
            mvnTestMode=""
            ;;
        it)
            echo -e "Disabling unit tests\n"
            mvnTestMode="-DskipUnitTests"
            ;;
        ut)
            echo -e "Disabling integration tests\n"
            mvnTestMode="-DskipIntTests"
            ;;
        *)
            echo -e "Unknown Maven test mode specified ($testOption), running unit tests\n"
            ;;
    esac
else
    echo "Test running mode not specified"
fi



cd $HONEYCOMB_HOME

mvn -V clean install -Dapache $mvnTestMode
[ $? -ne 0 ] && { exit 1; }

$HONEYCOMB_HOME/bin/install-honeycomb-jars.sh "$HONEYCOMB_HOME/HBaseAdapter" $honeycomb_lib

adapter_conf=$config_path/honeycomb.xml
if [ ! -d $config_path ]
then
  echo "Creating configuration path $config_path"
  sudo mkdir $config_path
fi

if [ ! -e $adapter_conf ]
then
  echo "Creating the honeycomb.xml from the repository."
  sudo cp $HONEYCOMB_HOME/honeycomb/honeycomb-example.xml $adapter_conf
fi

jar=mysqlengine-0.1.jar
if [ "$($HONEYCOMB_HOME/bin/check-honeycomb-xml.rb "$HONEYCOMB_HOME" $jar)" == "Update" ]
then
  echo "Updating honeycomb.xml, it's out of date"
  sudo $HONEYCOMB_HOME/bin/update-honeycomb-xml.rb "$HONEYCOMB_HOME" $jar
fi

echo "*** Don't forget to restart MySQL. The JVM doesn't autoreload the jar from the disk. ***"
