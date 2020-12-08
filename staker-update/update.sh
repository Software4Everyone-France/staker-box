#!/bin/sh

readonly installDir=$PWD

deploy () {
  [ ! -d "${installDir}/$1" ] && echo "Directory ${installDir}/$1 DOES NOT exists." && exit
  [ "$3" != "teku" ] && [ ! -f "${installDir}/$1/$2" ] && echo "File ${installDir}/$1/$2 DOES NOT exists." && exit

  echo "Deploy ${installDir}/$1/$2 -> /home/$1/bin/$2"
  sudo mv "${installDir}/$1/$2" "/home/$1/bin/$2"
  sudo chown -R "$1:$1" "/home/$1/bin/$2"
  sudo rm -f "/home/$1/$3"
  if [ "$3" != "teku" ]; then
    echo "Symlink /home/$1/bin/$2 -> /home/$1/$3"
    sudo -u "$1" ln -s "/home/$1/bin/$2" "/home/$1/$3"
  else
    echo "teku special"
    echo "Symlink /home/$1/bin/$2/bin/teku -> /home/$1/$3"
    sudo -u "$1" ln -s "/home/$1/bin/$2/bin/teku" "/home/$1/$3"
  fi
}

deploy 'beacon' "$(basename "${installDir}"/beacon/beacon-chain-*)" 'prysm'
deploy 'beacon' "$(basename "${installDir}"/beacon/lighthouse-*)" 'lighthouse'

deploy 'validator' "$(basename "${installDir}"/validator/validator-*)" 'prysm'
deploy 'validator' "$(basename "${installDir}"/validator/lighthouse-*)" 'lighthouse'
deploy 'validator' "$(basename "${installDir}"/validator/teku-*)" 'teku'

deploy 'slasher' "$(basename "${installDir}"/slasher/slasher-*)" 'prysm'

rm -Rf beacon/ slasher/ validator/
