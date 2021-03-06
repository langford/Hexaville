#!/usr/bin/env sh

UNAME=`uname`;
HEXAVILLE_HOME=$HOME/.hexaville;

if [ -d "$HEXAVILLE_HOME" ]; then
  echo "hexaville is already installed"
  exit 1
fi

if [[ $UNAME == "Darwin" ]]; then
  curl -OL https://rawgit.com/Hexaville/Binary/master/bin/latest/mac/Hexaville.zip
else
  if [[ $UNAME == "Linux" ]]; then
    UBUNTU_RELEASE=`lsb_release -a 2>/dev/null`;
    if [[ $UBUNTU_RELEASE == *"15.10"* ]]; then
      echo "Unsupported OS"
      exit 1
    else
      curl -OL https://rawgit.com/Hexaville/Binary/master/bin/latest/linux/Hexaville.zip
    fi
  else
    echo "Unsupported OS"
    exit 1
  fi
fi

mkdir -p $HEXAVILLE_HOME
mv Hexaville.zip $HEXAVILLE_HOME
cd $HEXAVILLE_HOME
unzip -o Hexaville.zip
RCFILE=`echo ${SHELL##*/}`rc
content=`cat $HOME/.${RCFILE}`
if [[ $content != *$HEXAVILLE_HOME* ]]; then
  echo "" >> $HOME/.${RCFILE}
  echo "export PATH=\"\$PATH:$HEXAVILLE_HOME\"" >> $HOME/.${RCFILE}
fi
