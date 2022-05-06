# Version 0.1

# 基础镜像
FROM tomcat:latest

# 维护者信息
MAINTAINER geeksun@csu.edu.cn

# 安装一些必要的包
RUN apt-get update && apt-get install vim -y

# 创建目标目录
RUN mkdir -p /usr/local/tomcat/webapps/BigBuckBunny

