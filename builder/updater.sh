#!/bin/sh

if [ -z "$1" ]
  then
    echo "Provide staker destination 'account@ip'"
    exit
fi


readonly updateDir=$PWD

echo "CLean out"
rm -rf out/
mkdir -p out/beacon out/validator out/slasher

echo "Update Prysm"

cd ~/git/prysm || exit
git pull

./prysm.sh beacon-chain --download-only
./prysm.sh validator --download-only
./prysm.sh slasher --download-only

echo "Dispatch latest $(find dist/ -maxdepth 1 -name 'beacon-chain-*-linux-amd64' | sort -r | head -n 1) file to out"

cp "$(find dist/ -maxdepth 1 -name 'beacon-chain-*-linux-amd64' | sort -r | head -n 1)"  "${updateDir}"/out/beacon/
cp "$(find dist/ -maxdepth 1 -name 'beacon-validator-*-linux-amd64' | sort -r | head -n 1)" "${updateDir}"/out/validator/
cp "$(find dist/ -maxdepth 1 -name 'beacon-slasher-*-linux-amd64' | sort -r | head -n 1)" "${updateDir}"/out/slasher/

echo "Update Lighthouse"

cd ~/git/lighthouse || exit

echo "   update rust"
rustup update stable

git pull
readonly lighthouseVersion=$(git describe --tags)
make

echo "Dispatch lighthouse-${lighthouseVersion} to out"
cd "${updateDir}" || exit
cp ~/git/lighthouse/target/release/lighthouse "${updateDir}"/out/beacon/lighthouse-"${lighthouseVersion}"
cp ~/git/lighthouse/target/release/lighthouse "${updateDir}"/out/validator/lighthouse-"${lighthouseVersion}"

echo "Update Teku"

cd ~/git/teku || exit
git pull
readonly tekuVersion=$(git describe --tags)
./gradlew distTar installDist

echo "Dispatch teku-${tekuVersion} to out"
cd "${updateDir}" || exit
cp -r ~/git/teku/build/install/teku/ "${updateDir}"/out/validator/teku-"${tekuVersion}"

echo "Done"

#cd ~/git/eth2stats-client
#git pull
#make build

#cd ${updateDir}
#cp ~/git/eth2stats-client/eth2stats-client ${updateDir}/out

scp -Cr "${updateDir}"/out/* "$1":~/staker-update/.
