# H5AI 基于 Nginx + PHP7.0.x 的 一键安装脚本

* h5ai is a modern file indexer for HTTP web servers with focus on your files. Directories are displayed in a appealing way and browsing them is enhanced by different views, a breadcrumb and a tree overview. Initially h5ai was an acronym for HTML5 Apache Index but now it supports other web servers too.

# 注意事项
* 推荐使用纯净状态的发行版系统安装
* 该脚本与本人的 V2RAY 一键脚本共存

# 安装方式

```
git clone https://github.com/yanshibin/h5ai_onekey_install-lnp-.git h5ai
cd h5ai
bash h5ai.sh |tee h5ai.log
```
# 默认安装路径

* Nginx：`/etc/nginx`
* PHP: `/etc/php/7.0`
* h5ai目录：`/home/wwwroot/your_domain`

# 更新日志
### 2017-12-15
V2.0
* 添加一键 SSL 配置功能
* 添加域名 IP 验证
* 部分 bug 修复
* 相关依赖完善
### 2017-12-14
V1.0
* 实现 H5AI 基本功能
* 完善安装相关所需依赖

