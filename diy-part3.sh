#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# 移除要替换的包
#rm -rf feeds/packages/net/v2ray-geodata
#rm -rf feeds/packages/net/mosdns
#rm -rf feeds/luci/applications/luci-app-mosdns

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# 添加额外插件
git_sparse_clone master https://github.com/kiddin9/openwrt-packages luci-app-argon-config
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash
git_sparse_clone master https://github.com/kiddin9/openwrt-packages luci-app-aliddns
git_sparse_clone master https://github.com/kiddin9/openwrt-packages luci-app-filebrowser filebrowser
git_sparse_clone master https://github.com/kiddin9/openwrt-packages luci-app-jellyfin luci-lib-taskd luci-lib-xterm taskd
git_sparse_clone master https://github.com/kiddin9/openwrt-packages luci-app-linkease linkease ffmpeg-remux
#git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
#git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# iStore
#git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
#git_sparse_clone main https://github.com/linkease/istore luci

# 更换 Nodejs 版本
rm -rf ./feeds/packages/lang/node
git clone https://github.com/sbwml/feeds_packages_lang_node-prebuilt feeds/packages/lang/node

# 加入OpenClash核心
#chmod -R a+x $GITHUB_WORKSPACE/preset-clash-core.sh
#$GITHUB_WORKSPACE/preset-clash-core.sh

# 动态DNS
sed -i '/boot()/,+2d' feeds/packages/net/ddns-scripts/files/etc/init.d/ddns
cp -rf ../openwrt-third/ddns-scripts_aliyun ./feeds/packages/net/ddns-scripts_aliyun
ln -sf ../../../feeds/packages/net/ddns-scripts_aliyun ./package/feeds/packages/ddns-scripts_aliyun

# Dnsfilter
git clone --depth 1 https://github.com/kiddin9/luci-app-dnsfilter.git package/new/luci-app-dnsfilter

# socat
cp -rf ../Lienol_pkg/luci-app-socat ./package/new/luci-app-socat
pushd package/new
wget -qO - https://github.com/Lienol/openwrt-package/pull/39.patch | patch -p1
popd
sed -i '/socat\.config/d' feeds/packages/net/socat/Makefile

# 晶晨宝盒
#git_sparse_clone main https://github.com/ophub/luci-app-amlogic luci-app-amlogic
#sed -i "s|firmware_repo.*|firmware_repo 'https://github.com/haiibo/OpenWrt'|g" package/luci-app-amlogic/root/etc/config/amlogic
# sed -i "s|kernel_path.*|kernel_path 'https://github.com/ophub/kernel'|g" package/luci-app-amlogic/root/etc/config/amlogic
#sed -i "s|ARMv8|ARMv8_PLUS|g" package/luci-app-amlogic/root/etc/config/amlogic


echo "
# openclash
#CONFIG_PACKAGE_luci-app-openclash=y

# 阿里DDNS
#CONFIG_PACKAGE_luci-app-aliddns=y

# filebrowser
#CONFIG_PACKAGE_luci-app-filebrowser=y

# Jellyfin
#CONFIG_PACKAGE_luci-app-jellyfin=y

# 易有云
#CONFIG_PACKAGE_luci-app-linkease=y

" >> .config

# 修改默认IP
sed -i 's/192.168.1.1/192.168.2.99/g' package/base-files/files/bin/config_generate

# 修改默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# x86 型号只显示 CPU 型号
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

# 修改本地时间格式
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

# 取消默认的 autosamba 依赖的 luci-app-samba 到 slim 里
find  ./target/linux/ -maxdepth 2 -type f  -name Makefile -exec sed -i 's#autosamba##' {} \;

