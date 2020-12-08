#!/bin/sh

if [ -z "$1" ]
  then
    echo "Provide staker destination 'account@ip'"
    exit -1
fi


readonly updateDir=$PWD

echo "CLean out"
rm -rf out/
mkdir -p out/beacon out/validator out/slasher

echo "Update Prysm"

cd ~/git/prysm
git pull

./prysm.sh beacon-chain --download-only
./prysm.sh validator --download-only
./prysm.sh slasher --download-only

echo "Dispatch latest $(ls dist/beacon-chain-*-linux-amd64 | tail -1) file to out"

cp $(ls dist/beacon-chain-*-linux-amd64 | tail -1) ${updateDir}/out/beacon/
cp $(ls dist/validator-*-linux-amd64 | tail -1) ${updateDir}/out/validator/
cp $(ls dist/slasher-*-linux-amd64 | tail -1) ${updateDir}/out/slasher/

echo "Update Lighthouse"

cd ~/git/lighthouse

echo "   update rust"
rustup update stable

git pull
readonly lighthouseVersion=$(git describe --tags)
make

echo "Dispatch lighthouse-${lighthouseVersion} to out"
cd ${updateDir}
cp ~/git/lighthouse/target/release/lighthouse ${updateDir}/out/beacon/lighthouse-${lighthouseVersion}
cp ~/git/lighthouse/target/release/lighthouse ${updateDir}/out/validator/lighthouse-${lighthouseVersion}

echo "Update Teku"

cd ~/git/teku
git pull
readonly tekuVersion=$(git describe --tags)
./gradlew distTar installDist

echo "Dispatch teku-${tekuVersion} to out"
cd ${updateDir}
cp -r ~/git/teku/build/install/teku/ ${updateDir}/out/validator/teku-${tekuVersion}

echo "Done"

#cd ~/git/eth2stats-client
#git pull
#make build

#cd ${updateDir}
#cp ~/git/eth2stats-client/eth2stats-client ${updateDir}/out

scp -Cr ${updateDir}/out/* $1:~/staker-update/.
