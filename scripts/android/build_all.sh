#!/bin/sh

if [ -z "$APP_ANDROID_TYPE" ]; then
	echo "Please set APP_ANDROID_TYPE"
	exit 1
fi

DIR=$(dirname "$0")

case $APP_ANDROID_TYPE in
	"monero.com") $DIR/build_monero_all.sh || exit 1
	;;
	"cakewallet") $DIR/build_monero_all.sh || exit 1
				  $DIR/build_haven.sh  || exit 1
				  ;;
	"haven")      $DIR/build_haven_all.sh || exit 1
	;;
esac
