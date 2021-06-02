## Bee 0.6.2 一键安装 & 升级脚本

本脚本用于批量一键安装/升级`bee` 0.6.2 版本

### 如何使用

**⚠️ 请在执行此脚本前备份好您相关数据**

1. 下载此脚本，给予执行权限 `chmod +x deploy.sh`
2. 替换`BEE_SWAP_ENDPOINT`为你申请的`infura.io`地址
3. 执行 `./deploy.sh`

### 说明

1. 本脚本安装的`bee` 默认以`full-node` 模式运行
2. 请务必使用`root`用户执行此脚本
3. 本脚本仅在`Ubuntu 20.0.4`上测试运行过，不保证其他版本，平台能够正常运行
4. 脚本成功执行后会写入别名`bec`,`beco`,`becp`

   1. `bec` 等同于 `curl -s localhost:1635/chequebook/cheque`
   2. `beco` 等同于 `/root/cashout.sh cashout-all`
   3. `becp` 等同于 `curl -s localhost:1635/peers | jq '.peers | length'`

5. 脚本执行完毕后默认会添加定时`cashout`功能，但经过最近多次测试，执行`cashout-all`时`bee`会无响应，继而导致不停重试最终将 infura 的配额消耗殆尽，请慎重使用此功能。
6. `cashout.sh` 脚本来源于 `https://gist.github.com/ralph-pichler/3b5ccd7a5c5cd0500e6428752b37e975`
