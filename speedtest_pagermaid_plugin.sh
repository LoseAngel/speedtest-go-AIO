#!/bin/bash
checkspeedtest() {
	if  [ ! -e '/pagermaid/workdir/speedtest-cli/speedtest' ]; then
		wget --no-check-certificate -qO speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.0.0-$(uname -m)-linux.tgz
		#wget --no-check-certificate -qO speedtest.tgz https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-$(uname -m)-linux.tgz 
	fi
	mkdir -p speedtest-cli && tar zxvf speedtest.tgz -C ./speedtest-cli/ > /dev/null 2>&1 && chmod a+rx ./speedtest-cli/speedtest
}

runall() {
	checkspeedtest;
}
echo 'before run'
runall
