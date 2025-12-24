# node 业务基础镜像
FROM node:20.17.0-slim

RUN echo "Asia/Shanghai" > /etc/timezone
RUN echo "ZONE=Asia/Shanghai" >> /etc/timezone && rm -f /etc/localtime && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN apt-get update && apt-get install -y curl git vim

RUN npm config set registry https://registry.npmmirror.com

RUN npm i pnpm -g
