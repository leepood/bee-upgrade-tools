#!/bin/bash

# CHANGE THIS BEFORE RUN YOUR SCRIPT
BEE_SWAP_ENDPOINT=wss://goerli.infura.io/ws/v3/xxxxxxxxxxxx
BEE_WELCOME_MESSAGE="🐝🐝 Hello, Greeting from bzz which was installed by https://github.com/leepood 🐝🐝"
BEE_FULL_NODE=true

function version_lt() {
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"
}

function log_succ() {
    echo -e "\033[32m$1\033[0m"
}

function getPackageVersion() {
    status=$(dpkg-query -s "$1" | grep -E "^Status" | awk '{print $2}')
    if [ $status !=  "install" ];then
        echo "0.0.0"
    else
        dpkg-query -s "$1" | grep -E "^Version" | awk '{print $2}'
    fi
}

function installJq() {
    if [ ! -f /usr/bin/jq ]; then
        echo "Install jq"
        apt install -y jq
    fi
}

function getServiceStatus() {
    service "$1" status | grep Active | awk {'print $2}'
}

function addSwap() {
    swap=$(swapon -s)
    if [ -z "$swap" ]; then
        echo "NO SWAP, ADD NOW..."
        mkdir swap
        cd swap
        dd if=/dev/zero of=sfile bs=1024 count=2000000
        mkswap sfile
        swapon sfile
        echo "/root/swap/sfile  none  swap  sw  0  0" >>/etc/fstab
        log_succ "Swap Done"
    fi
}

function installCashout() {
    # download cashout.sh without check, just override
    echo "Download Cashout.sh"
    cd ~
    wget -O cashout.sh --quiet https://gist.githubusercontent.com/leepood/c121e416703a708ac2c7829525774334/raw/2ea20bf9912886121c69af1ca7f0b5568ecfd176/cashout.sh
    chmod +x cashout.sh
}

function installBeeClef() {
    beeClefVer=$(getPackageVersion "bee-clef")
    echo "Current Bee-Clef Version:"$beeClefVer
    if version_lt $beeClefVer "0.4.12"; then
        echo "Install Bee-Clef 0.4.12"
        cd /tmp
        wget -O bee-clef_0.4.12_amd64.deb --quiet https://github.com/ethersphere/bee-clef/releases/download/v0.4.12/bee-clef_0.4.12_amd64.deb
        apt install ./bee-clef_0.4.12_amd64.deb -o Dpkg::Options::="--force-confold"
    else
        log_succ "Bee-Clef 0.4.12 has installed"
    fi

    # Check service status
    status=$(getServiceStatus "bee-clef")
    if [ $status != "active" ]; then
        echo "Enable & Start Bee-Clef Service"
        systemctl enable bee-clef
        systemctl start bee-clef
    fi
    log_succ "Bee-Clef service started"
}

function installBee() {
    beeVer=$(getPackageVersion bee)
    if version_lt $beeVer "0.6.1"; then
        echo "Install Bee 0.6.1"
        cd /tmp
        wget -O bee_0.6.1_amd64.deb --quiet https://github.com/ethersphere/bee/releases/download/v0.6.1/bee_0.6.1_amd64.deb
        apt install -o Dpkg::Options::="--force-confold" ./bee_0.6.1_amd64.deb
        # assume we have installed bee successfully, we need upgrade configuration
        cat <<EOF >/etc/default/bee
BEE_SWAP_ENDPOINT=$BEE_SWAP_ENDPOINT
BEE_WELCOME_MESSAGE="$BEE_WELCOME_MESSAGE"
BEE_FULL_NODE=$BEE_FULL_NODE
EOF
    fi

    # Check service status
    status=$(getServiceStatus bee)
    if [ $status != "active" ]; then
        log_succ "Enable & Start Bee Service"
        systemctl enable bee
        systemctl start bee
    fi
    log_succ "Bee service Started...."
}

function addAliasUtil() {
    aliasBeeCo=$(alias | grep bec)
    if [ -z "$aliasBeeCo" ]; then
        alias bec='curl -s localhost:1635/chequebook/cheque | jq'
        echo "alias bec='curl -s localhost:1635/chequebook/cheque | jq'" >>/root/.bashrc
        source /root/.bashrc
    fi

    aliasBeeCashout=$(alias | grep beco)
    if [ -z "$aliasBeeCashout" ]; then
        alias beco='/root/cashout.sh cashout-all'
        echo "alias beco='/root/cashout.sh cashout-all'" >>/root/.bashrc
        source /root/.bashrc
    fi

    aliasBeePeers=$(alias | grep bep)
    if [ -z "$aliasBeePeers" ]; then
        alias bep="curl -s localhost:1635/peers | jq '.peers'"
        echo "alias bep=\"curl -s localhost:1635/peers | jq '.peers | length'\" " >>/root/.bashrc
        source /root/.bashrc
    fi
}

function addCronJob() {
    echo "Check Crontab Jobs"
    crontabs=$(crontab -l 2>/dev/null | grep "cashout" | wc -l)
    if (($crontabs < 1)); then
        echo "Add Crontab"
        crontab -l | {
            cat
            echo "0 */6 * * * bash /root/cashout.sh cashout-all"
        } | crontab -
    fi
}

function exportBeeKeys() {
    privateKey=$(ls /var/lib/bee-clef/keystore/)
    echo "Key file name: "$privateKey
    echo "Private Key: "
    cat "/var/lib/bee-clef/keystore/"$privateKey | jq
    password=$(cat /var/lib/bee-clef/password)
    echo "Password: "$password
}

addSwap
installJq
installCashout
installBeeClef
installBee
addAliasUtil
addCronJob
exportBeeKeys

