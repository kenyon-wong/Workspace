#!/usr/bin/python
# -*- coding:utf-8 -*-

import pycurl
import io
import urllib
from io import BytesIO

##########参数部分，需要根据实际情况修改##########
# 接口IP
host = '192.168.1.112'

# 全局参数配置
username = 'admin'
password = '760421Zs@'
result_format = 'xml'

# 请求参数（POST）
# XML路径
config_xml = 'config.xml'
# 任务名称
name = 'test'
# 扫描目标
targets = '8.8.8.8'

# https://{device_ip}/api/{api_name}?{query_string}
url = 'https://' + host + '/api/task/create?username=' + username + '&password=' + password + '&format=' + result_format

io = io.BytesIO()
curl = pycurl.Curl()
curl.setopt(pycurl.URL,url)
curl.setopt(pycurl.WRITEFUNCTION, io.write)
curl.setopt(pycurl.SSL_VERIFYPEER, 0)
curl.setopt(pycurl.SSL_VERIFYHOST, 0)

# POST请求参数type和config_xml
curl.setopt(pycurl.HTTPPOST, [('config_xml',(curl.FORM_FILE, config_xml)),
                              ('type',(curl.FORM_CONTENTS, task_type)),
			      ])
curl.perform()
ret = io.getvalue()

#print (ret)
print(bytes.decode(ret))
io.close()
curl.close()
