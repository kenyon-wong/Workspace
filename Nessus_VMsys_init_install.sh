#VM 兼容性： ESXi 6.5

# 修改主机名
echo "Nessus-1" >/etc/hostname

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

yum install epel-release -y

#修改EPEL源
sed -e 's,^#baseurl,baseurl,g' \
    -e 's,^metalink,#metalink,g' \
    -e 's,^mirrorlist=,#mirrorlist=,g' \
    -e 's,http://download.fedoraproject.org/pub,https://mirrors.aliyun.com,g' \
    -i /etc/yum.repos.d/epel.repo

yum clean all && yum makecache && yum update -y

#安装自定义的第三方工具，方便以后使用
yum groups install base -y

#在不需要的软件名称之前添加井号进行注释即可
yum install -y vim gcc make wget ntp nc tree parallel htop \
wireshark \
git \
tcpdump \
libpcap-devel \
socat \
nmap \
python3 \
python3-pip \
p7zip* \
flex \
iotop \
dstat \
perf \

#配置系统时区为上海并校准时间
systemctl enable ntpd && systemctl restart ntpd
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
date 

#安装 Nessus
#-----------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------
#此处代码不完善，只能供参考使用
#-----------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------

wget https://www.tenable.com/downloads/api/v1/public/pages/nessus/downloads/11664/download?i_agree_to_tenable_license_agreement=true
rpm -ivh Nessus-8.12.0-es7.x86_64.rpm
systemctl start nessusd.service
/opt/nessus/sbin/nessuscli fetch --challenge #获取 challenge code
/opt/nessus/sbin/nessuscli update /opt/nessus/sbin/all-2.0.tar.gz
cp /opt/nessus/sbin/nessus-fetch.rc /opt/nessus/etc/
/opt/nessus/sbin/nessuscli fetch --register-offline /opt/nessus/sbin/nessus.license


#-----------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------
# 以下内容是待完善部分
#-----------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------

#此处可以考虑增加用户执行脚本时提供邮件中的激活码，同时在脚本中提取 challenge 的值作为变量以自动完成
#get_challenge="/opt/nessus/sbin/nessuscli fetch --challenge"
#EMaliCode=""
#CHALLENGE="$($get_challenge|grep Copying |grep version |awk -F '[ ]' '{print $5}')" #此处只是简单的dome
#https://plugins.nessus.org/register.php?serial=<激活码>
#UpdateZip=https://plugins.nessus.org/v2/nessus.php?f=all-2.0.tar.gz&u=<username>&p=<password>



cp ~/plugin_feed_info.inc /opt/nessus/lib/nessus/plugins/
cp ~/plugin_feed_info.inc /opt/nessus/var/nessus/
chown root:admin /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc && chmod 644 /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc
chown root:admin /opt/nessus/var/nessus/plugin_feed_info.inc && chmod 644 /opt/nessus/var/nessus/plugin_feed_info.inc

#防火墙放行 Nessus Web服务的默认端口
firewall-cmd --zone=public --add-port=8834/tcp --permanent
firewall-cmd --reload

systemctl restart nessusd.service
firefox https://127.0.0.1:8843

#此处是 plugin_feed_info.inc 文件内容的参考模板
# PLUGIN_SET 的值需要修改，其值来源于执行 all-2.0.tar.gz 更新之后的版本值

#[root@Nessus-1 Desktop]# cat plugin_feed_info.inc
#PLUGIN_SET = "202009231305";
#PLUGIN_FEED = "ProfessionalFeed (Direct)";
#
#
#PLUGIN_FEED_TRANSPORT = "Tenable Network Security Lightning";
#[root@Nessus-1 Desktop]#

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
history -c && shutdown -h now