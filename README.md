# 问题

## 背景

MPEG-DASH（HTTP上的动态自适应流传输，ISO / IEC 23009-1）是由MPEG和ISO批准的独立于供应商的国际标准，它是一种基于HTTP的使用TCP传输协议的流媒体传输技术。MPEG-DASH是一种自适应比特率流技术，可根据实时网络状况实现动态自适应下载。

它会将媒体内容封装成一系列小型的基于 HTTP 的文件片段，每个片段包含的时间可以设置，一般包含时间较短但是每个片段有多种码率的版本，这样可以更精确地实现网络自适应下载。客户端将根据当前网络条件自适应地选择下载和播放当前网络能够承载的最高比特率版本，这样既可以保证当前媒体的质量又能避免由于码率过高导致的播放卡顿或重新缓冲事件。下图简要概述了视频的多种质量被编码、分块并由流媒体客户端/播放器请求的过程。
<div align=center>
<img src="https://user-images.githubusercontent.com/42086593/167096355-5f1d78c5-d5e6-4209-acfc-3a8b442375fd.png"/>
</div>



MPEG-DASH传输系统架构由HTTP服务器和DASH客户端两部分组成。HTTP服务器存储着DASH文件，主要包含两部分：媒体描述文件MPD和DASH媒体文件。DASH媒体文件主要由分段媒体文件和头信息文件两部分组成。为了精确描述DASH的结构内容，MPEG-DASH引入了Media Presentation Description (MPD)的概念。MPD是一个XML文件，它完整描述了DASH内容的所有信息，包括各类音视频参数、内容分段时长、不同媒体分段的码率和分辨率以及对应的访问地址URL等等，客户端通过首先下载并解析MPD文件，可获取到与自身性能和带宽最匹配的媒体分段。下图比较清晰地说明了MPD文件的分层结构关系。
<div align=center>
<img src="https://user-images.githubusercontent.com/42086593/167097069-e6a99890-a330-419c-aeb1-2e44f7d96d54.png"/>
</div>

### Period

一个DASH文件可以包含一个或多个Periods，每个Period代表一段连续的视频片段，假设一段码流有60s被划分为3个Periods，Period1为0-15s，Period2为16-40s，Period3为41-60s。在同一个Period内，可用的媒体内容的类型及其各个可用码率(Representation)都不会发生变更。

### AdaptationSet

一个Period由一个或多个AdaptationSets组成。例如，一个自适应集包含同一视频内容的多个不同比特率的视频分段，另一个自适应集包含同一音频内容的多个不同比特率的视频分段。每个AdaptationSet包含了逻辑一致的可供切换的不同码率的码流。

### Representation

一个AdaptationSet由一组媒体内容配置可切换的Representations构成。每个Representation表示同一媒体内容但编码参数互不相同的音视频数据。包含了相同媒体内容的不同配置，即不同的分辨率、码率等，以供客户端根据自身的网络条件和性能限制来选择合适的版本下载播放。

### Segment

每个Representation中的内容按时间或者其他规则被切分成一段段Segments，使得客户端在播放时能够灵活地在不同的Representations之间进行切换。每个Segment都有一个唯一的与之对应的URL地址，也可能由相同的URL与不同的byte range指定。DASH客户端可以通过HTTP协议来获取URL对应的分片数据。MPD中描述Segment URL的形式包括Segment list，Segment template，Single segment。

## 实验目的

-   熟悉Wireshark、docker、NetBalancer Tray的基本使用方法
-   探究在当前实验环境下MPEG-DASH最佳段长度
-   分析视频传输过程中的HTTP与TCP包结构
-   分析不同段长度对网络吞吐量的影响及其原因。

## 实验环境

操作系统：windows xp/windows 10/windows 11

软件: vlc播放器、wireshark、NetBalancer Tray、docker

Web Server: TOMCAT

## 前置知识

1.  学习docker的基本使用方法（可参考[菜鸟教程](https://www.runoob.com/docker/docker-tutorial.html)）
2.  学习wireshark的使用方法
3.  学习基本的linux命令（可参考[菜鸟教程](https://www.runoob.com/linux/linux-tutorial.html)）

## 环境搭建

1、下载安装[vlc播放器](https://www.videolan.org/)

2、下载安装[wireshark](https://www.wireshark.org/#download)

3、下载安装[NetBalancer Tray](https://netbalancer.com/download)

4、下载安装[docker](https://www.docker.com/get-started/)（可能需要配置好环境变量）

5、下载DASH文件

<https://pan.baidu.com/s/1Rkjo-wSc1Af-bSAtrJg2_w?pwd=ytf4>

提取码: ytf4

6、搭建web服务器

(1) 创建一个工作目录，并将Dockerfile下载到该工作目录

<https://pan.baidu.com/s/13KI9Z58nPzHGTGOwZXpQPg?pwd=76nx>

提取码: 76nx

(2) 将DASH文件解压缩到当前工作目录。（使用7zip全选并解压）

(3) 打开命令提示符，切换目录到工作目录。如下，默认目录为用户根目录，输入命令 cd + 工作目录绝对路径

cd C:\\Users\\99570\\Desktop\\计算机网络课件\\网络实验\\docker

![image](https://user-images.githubusercontent.com/42086593/167097912-2808edd0-95d4-4859-8836-806850ab4d6f.png)

(4) 在命令提示符中输入

docker build -t network-experiment:0.1 .

构建docker镜像（network-experiment是镜像的名字，可自定义，但后续的命令也需要相应的修改）输入命令docker images，可查看镜像是否拉取成功。

![image](https://user-images.githubusercontent.com/42086593/167097892-f758e4e7-6f45-48b3-905f-7bb9f79f75ee.png)

(5)输入命令 （工作目录绝对路径需修改成你的路径）

docker run -it -d -p 8080:8080 --name web-server -v C:/Users/99570/Desktop/计算机网络课件/网络实验/docker/BigBuckBunny:/usr/local/tomcat/webapps network-experiment:0.1

(6)成功启动会显示如下提示

![image](https://user-images.githubusercontent.com/42086593/167097859-5ac6b735-ee46-4db9-b1df-5b8feac61b12.png)

（当容器创建成功后，不需要重复创建了，通过命令docker stop 容器ID关闭当前容器，docker start 容器ID启动容器）

## 实验步骤

（1）打开NetBalancer Tray，软件界面如下

![image](https://user-images.githubusercontent.com/42086593/167097608-a1837408-d2f5-4a15-b5e5-cc0ed19336fd.png)

(2)打开wireshark，双击adapter for loopback traffic capture。

![image](https://user-images.githubusercontent.com/42086593/167097583-e69eaf32-b497-43a5-bb81-ebca3084469d.png)

(3)打开vlc播放器，点击媒体、网络串流、输入

<http://127.0.0.1:8080/BigBuckBunny/bunny_1s/BigBuckBunny_1s_isoffmain_DIS_23009_1_v_2_1c2_2011_08_30.mpd>

即可播放视频。（注：当前可选的视频段长度有1s、2s、4s、6s、10s、15s，测试不同段长度的视频需将链接中的1s改成目标时间长度）

(4)在NetBalancer Tray中右键点击traffic Chart，点击Filter，选择vlc.exe，右键点击view，单击Custom Traffic Range，可选择检测流量时间段，建议选择300s，或者选择播放完整个视频的时间。（单击图表可暂停监测或右键图表将当前检测数据保存至本机，进行后续分析）

结果如下:

![image](https://user-images.githubusercontent.com/42086593/167097486-b391393b-8d24-4806-8676-9324f40d8a0b.png)

(5)打开wireshark在过滤器中输入tcp.port == 8080，即可开始捕获目标数据包。

![image](https://user-images.githubusercontent.com/42086593/167097138-2475d1f3-4175-4686-a4ee-b31c659513f6.png)
