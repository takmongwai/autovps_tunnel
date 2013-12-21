#!/usr/local/rvm/rubies/ruby-1.9.3-p362/bin/ruby
# encoding: utf-8
#
# 生成haproxy配置文件
# 生成ssh执行脚本
# 执行ssh连接
# 执行haproxy

require 'rubygems'
require 'pp'
require 'erb'
require 'yaml'

path = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__

curr_dir = File.dirname(path)

haproxy_cfg = ERB.new(File.read(curr_dir + '/haproxy.cfg.erb'),nil,'%<>-')
sshtunnel_sh = ERB.new(File.read(curr_dir + '/sshtunnel.sh.erb'),nil,'%<>-')
system("cp #{curr_dir+'/ha_ssh_config'} /tmp/")

LISTEN_ADDRESS = "0.0.0.0"
#socket 监听端口,客户端连接到这个端口作为代理服务器
LISTEN_PORT = 1099
#ssh隧道的起始端口
SSH_TUNNEL_START_PORT = 2200
#每个ssh服务器的总连接数
SSH_TUNNEL_COUNT = 200
#SSH服务器列表
SSH_SERVERS = %w(vps)

#所有ssh tunnel 的端口

@ssh_commands = []

#每个ssh端口数x服务器的数量
start_port = SSH_TUNNEL_START_PORT
SSH_SERVERS.each_with_index do |server,index|
  fix_idx ||= index #unless fix_idx
  fix_idx+=1
  @ssh_commands << {
    :server => server,
    :ports => start_port.upto( (start_port + SSH_TUNNEL_COUNT)  ).map{|i| i},
    :monitor_port => (SSH_TUNNEL_START_PORT + SSH_TUNNEL_COUNT * (SSH_SERVERS.size + 1) + fix_idx)
  }
  start_port += SSH_TUNNEL_COUNT + 1
end

@ssh_tunnel_ports = SSH_TUNNEL_START_PORT.upto(start_port-1).map{|i| i}.shuffle!

File.open("/tmp/haproxy.cfg","w") do  |f|
  f.write haproxy_cfg.result()
  f.chmod(0755)
end

File.open("/tmp/sshtunnel.sh","w") do |f|
  f.write sshtunnel_sh.result()
  f.chmod(0755)
end

system("/tmp/sshtunnel.sh")
