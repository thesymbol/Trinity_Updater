#!/bin/sh

# Settings
USER=""                                                 # The username of the system that runs the server. default: ""
TCREPO="https://github.com/TrinityCore/TrinityCore.git" # The repository to use to download. default: https://github.com/TrinityCore/TrinityCore.git
TCBRANCH="3.3.5"                                        # The branch of the repository to use. default: 3.3.5

# Compile settings
SOURCEDIR="/home/$USER/TrinityCore"                     # The directory to download the source to. default: /home/$USER/TrinityCore
BUILDTOOLS="0"                                          # Do we want to build the map extractors etc? default: 0
SCRIPTS="static"                                        # Scripts build mode. default: static
CORES="1"                                               # Amount of cores to use for building source. default: 1

# Installation settings
SERVERINSTALLDIR="/home/$USER/server"                   # The directory where the server is installed. default: /home/{$USER}/server
SERVERCONFIGDIR="/home/$USER/server/etc"                # The directory where the configuration files are located for the server. default: /home/{$USER}/server/etc
BACKUPPATH="/home/$USER/backup"                         # The temporary download path. default: /home/$USER/backup
SERVERSHUTDOWNTIME="3600"                               # shutdown time in seconds. default: 3600 (1 hour)

# DO NOT TOUCH BELOW

##  usage()
##  Reads:    NONE
##  Modifies: NONE
##
##  Outputs help text to the console
usage()
{
cat << EOF
usage: $0 options

This script will try and download the latest version of TrinityCore and compile it.
And if everything goes according to plan it will initiate a shutdown of the server (after specified time).

OPTIONS:
   -r      Specify repository to use
             If -r is specified without -b then the script will
             prompt the user to enter the branch when needed
   -b      Repository branch
   -u      Username on the system that runs the server
   -s      Script build mode (ex. static)
   -a      Source path
   -t      Build tools
   -m      Shutdown time
   -d      Backup path
   -i      Installation path
   -c      Configuration path
   -j      Number of cores to use to build source
   -h      Displays this message
EOF
}

alreadyLatest()
{
    echo "You are already running the latest version of TrinityCore $TCBRANCH"
}

while getopts x."r:b:u:s:a:t:m:d:i:c:j:h:?" OPTION
do
     case $OPTION in
         r) TCREPO=$OPTARG ;;
         b) TCBRANCH=$OPTARG ;;
         u) USER=$OPTARG ;;
         s) SCRIPTS=$OPTARG ;;
         a) SOURCEDIR=$OPTARG ;;
         t) BUILDTOOLS=$OPTARG ;;
         m) SERVERSHUTDOWNTIME=$OPTARG ;;
         d) BACKUPPATH=$OPTARG ;;
         i) SERVERINSTALLDIR=$OPTARG ;;
         c) SERVERCONFIGDIR=$OPTARG ;;
         j) CORES=$OPTARG ;;
         h) usage; exit 1 ;;
         ?) usage; exit 1 ;;
     esac
done

echo "Welcome to the TrinityCore update script! Please wait..."

CURRENTREV=`echo $(cd $SOURCEDIR && git rev-parse HEAD)`
TEMPREMOTEREV=`git ls-remote $TCREPO $TCBRANCH | cut -d' ' -f1`
REMOTEREV=`echo $TEMPREMOTEREV | cut -d' ' -f1`

echo "Checking local version..."
if [ "$CURRENTREV" = "$REMOTEREV" ]; then alreadyLatest; exit 0; fi # if we are on latest rev dont update exit instead.
echo "Local version is out of date!"
echo "Starting update process..."

# remove last backup
echo "Removing old backup..."
rm -rf $BACKUPPATH
echo "Recreating backup folder..."
mkdir -p $BACKUPPATH


# Backup the current directory and server files.
echo "Copying source to backup folder..."
cp -r $SOURCEDIR $BACKUPPATH
echo "Copying server directory to backup folder..."
cp -r $SERVERINSTALLDIR $BACKUPPATH

# download latest source.
echo "Downloading latest version..."
cd $SOURCEDIR && git pull origin $TCBRANCH
echo "latest version downloaded!"

# remove old build dir and go into a new clean one
echo "Removing old build folder..."
rm -rf $SOURCEDIR/build
mkdir -p $SOURCEDIR/build
cd $SOURCEDIR/build

# configure cmake etc.
echo "Configuring new build folder..."
cmake ../ -DTOOLS=$BUILDTOOLS -DCMAKE_INSTALL_PREFIX=$SERVERINSTALLDIR -DCONF_DIR=$SERVERCONFIGDIR -DSCRIPTS="$SCRIPTS"

# make
echo "Compiling new server..."
make -j $CORES

# bring server down
echo "Shutting down server in x minutes..."
$(screen -r worldserver && server shutdown $SERVERSHUTDOWNTIME)

echo "Waiting for server to shutdown..."
sleep $SERVERSHUTDOWNTIME

# kill leftover instances of the server
echo "Killing leftover instances of server..."
killall screen

# make install
echo "Installing server..."
make install

# start servers again
echo "Starting server again..."
cd /home/$USER
./start.sh

echo "Update completed!"