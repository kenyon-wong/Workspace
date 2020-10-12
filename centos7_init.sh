#!/bin/bash

rm -rf /root/anaconda-ks.cfg /root/initial-setup-ks.cfg

# 修改网卡配置、root用户的远程 ssh 访问策略
sed -i 's/^.*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
echo "DNS1=1.2.4.8" >>/etc/sysconfig/network-scripts/ifcfg-ens33
echo "DNS1=114.114.114.114" >>/etc/sysconfig/network-scripts/ifcfg-ens33
sed -i 's/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-ens33

#重启网络、ssh
systemctl restart network.service
systemctl restart sshd

#更改系统镜像源为阿里云源
sed -e 's,^mirrorlist,#mirrorlist,g' \
    -e 's,^#baseurl,baseurl,g' \
    -e 's,http://mirror.centos.org,https://mirrors.aliyun.com,g' \
    -i /etc/yum.repos.d/*.repo

yum install -y epel-release

#修改EPEL源
sed -e 's,^#baseurl,baseurl,g' \
    -e 's,^metalink,#metalink,g' \
    -e 's,^mirrorlist=,#mirrorlist=,g' \
    -e 's,http://download.fedoraproject.org/pub,https://mirrors.aliyun.com,g' \
    -i /etc/yum.repos.d/epel.repo

yum clean all && yum makecache && yum update -y

yum groups install base -y

#在不需要的软件名称之前添加井号进行注释即可
yum install -y vim gcc make wget ntp nc tree parallel htop python3 python3-pip libpcap-devel \
git \
nmap \
tcpdump \
p7zip* \
wireshark \
socat \
flex \
iotop \
dstat \
perf

# 待验证
python3 -m pip install --upgrade pip && pip3 install xlsxwriter

#配置系统时区为上海并校准时间
systemctl enable ntpd && systemctl restart ntpd
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && date 

#配置lvs模块
cat > /etc/modules-load.d/ipvs.conf <<EOF
ip_vs
# 负载均衡调度算法-最少连接
ip_vs_lc
# 负载均衡调度算法-加权最少连接
ip_vs_wlc
# 负载均衡调度算法-轮询
ip_vs_rr
# 负载均衡调度算法-加权轮询
ip_vs_wrr
# 源地址散列调度算法
ip_vs_sh
EOF

#配置连接状态跟踪模块
cat > /etc/modules-load.d/nf_conntrack.conf <<EOF
nf_conntrack
nf_conntrack_ipv4
#nf_conntrack_ipv6
EOF

#配置kvm模块
cat > /etc/modules-load.d/kvm.conf <<EOF
# Intel CPU开启嵌套虚拟化
options kvm-intel nested=1
options kvm-intel enable_shadow_vmcs=1
options kvm-intel enable_apicv=1
options kvm-intel ept=1

# AMD CPU开启嵌套虚拟化
#options kvm-amd nested=1
EOF

#个性化配置 vim
cat > ~/.vimrc <<EOF
" 显示行号
set number
" 高亮光标所在行
set cursorline
" 打开语法显示
syntax on
" 关闭备份
set nobackup
" 没有保存或文件只读时弹出确认
set confirm
" 禁用modeline功能
set nomodeline
" tab缩进
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
" 默认缩进4个空格大小 
set shiftwidth=4 
" 文件自动检测外部更改
set autoread
" 高亮查找匹配
set hlsearch
" 显示匹配
set showmatch
" 背景色设置为黑色
set background=dark
" 浅色高亮显示当前行
autocmd InsertLeave * se nocul
" 显示输入的命令
set showcmd
" 字符编码
set encoding=utf-8
" 开启终端256色显示
set t_Co=256
" 增量式搜索 
set incsearch
" 设置默认进行大小写不敏感查找
set ignorecase
" 如果有一个大写字母，则切换到大小写敏感查找
set smartcase
" 不产生swap文件
set noswapfile
" 设置备份时的行为为覆盖
set backupcopy=yes
" 关闭提示音
set noerrorbells
" 历史记录
set history=10000
" 显示行尾空格
set listchars=tab:»■,trail:■
" 显示非可见字符
set list
" c文件自动缩进
set cindent
" 文件自动缩进
set autoindent
" 检测文件类型
filetype on
" 智能缩进
set smartindent
EOF

# 清理不需要的内核
/bin/package-cleanup  --oldkernels --count=1  -y

#关机制作模板
history -c
shutdown -h now