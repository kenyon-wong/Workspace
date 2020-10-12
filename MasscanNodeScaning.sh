#!/bin/bash

source /etc/profile
Time=$(date +%Y-%m-%d_%H-%M-%S)

#用户需自定义变量区域
Jobs=16
TaskName=NetMacScanner
MailTitle="$Time-管控侧扫描集群-网管中心-活跃主机扫描-IN-$HOSTNAME-From-Masscan&Nmap"
Mails="kenyons@139.com"

WorkDIR=/root/scanner
TargetTxt=$WorkDIR/Target/$TaskName-$HOSTNAME.txt 
MasscanOutDir=/$WorkDIR/Results/$TaskName-$Time
Ports=$WorkDIR/Target/$TaskName-Ports_$Time.txt

MasscanPut=$WorkDIR/Target/$TaskName-Masscan_$Time-$HOSTNAME.txt
MasscanOut=$WorkDIR/Results/$TaskName-Masscan_$Time-$HOSTNAME.xml

OutName=$WorkDIR/Results/$TaskName-$Time-$HOSTNAME.txt
RHOSTIP="$(ip a |grep ens |grep inet |awk -F '[ /.]' -v OFS="." '{print $6,$7,$8}').60"

print "1-16383\n16384-32767\n32768-49151\n49152-65535\n" >$Ports

madir -p $MasscanOutDir && cd $MasscanOutDir

#对扫描目标进行去重
sort -ur $TargetTxt |sort |uniq >$MasscanPut

#以并行扫描模式启动 masscan 开始扫描
parallel -j $Jobs "masscan -p {2} {1} --rate=1000 -oX {1}.xml" :::: $MasscanPut :::: $Ports

#对 masscan 输出的扫描结果进行处理
grep address $MasscanOutDir/*.xml |awk -F '["]' -v OFS='\t' '{print $4,$6,$8,$10,$12,$14,$16}' |sort -ur |sort |uniq >$OutName
scp $OutName root@RHOSTIP:$WorkDIR/Results

#对扫描输出的文件进行压缩归档
7za a -t7z -r $WorkDIR/Results/$TaskName-$Time.7z $MasscanOutDir/*

#清除扫描过程中的中间文件
rm -rf $MasscanPut $MasscanOutDir $Ports

#清除过期（创建时间大于30天的 masscan 扫描输出文件及其文件归档）
find $WorkDIR/Results/ -mtime +30 -exec rm -rf {} \; 