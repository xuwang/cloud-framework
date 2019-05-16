#!/bin/bash -e

###################################################################################
# Install sonar-scanner
####################################################################################

THIS_DIR=$(dirname "$0")
FRAMEWORK_DIR=${FRAMEWORK_DIR:-..}

if command -v sonar-scanner ; then exit 0; fi

SONAR_SCANNER_VERSION=${SONAR_SCANNER_VERSION:-"3.3.0.1492"}
INSTALL_DIR=${SONAR_SCANNER_INSTALL_DIR:-$HOME/bin}

case "$OSTYPE" in
        "linux-gnu" ) 
            os=linux
            zipfile=sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip
            ;;
        "darwin"*   ) 
            os=macosx
            zipfile=sonar-scanner-cli-${SONAR_SCANNER_VERSION}-macosx.zip
            ;;
        "win32"     )
            os=windows
            zipfile=sonar-scanner-cli-${SONAR_SCANNER_VERSION}-windows.zip
            ;;
        *           )
            os=""
            file=sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip
            ;;
esac

if [ "$os" == "windows" ]; then
    echo "Please install sonar-scan from https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner"
    exit 1;
fi

curl https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/${zipfile} >/tmp/sonar-scanner.zip
unzip /tmp/sonar-scanner.zip -d ${INSTALL_DIR}
ln -sf ${INSTALL_DIR}/sonar-scanner-${SONAR_SCANNER_VERSION}-${os}/bin/sonar-scanner ${INSTALL_DIR}/sonar-scanner
rm -f /tmp/sonar-scanner.zip

echo "sonar-scan is installed in INSTALL_DIR"
