<!--
 * @Description: Editor's info in the top of the file
 * @Author: p1ay8y3ar
 * @Date: 2021-08-08 22:06:57
 * @LastEditor: p1ay8y3ar
 * @LastEditTime: 2021-08-08 22:11:59
 * @Email: p1ay8y3ar@gmail.com
-->
# 安装
`sudo snap install --classic certbot`

`sudo ln -s /snap/bin/certbot /usr/bin/certbot`

# 签名 
`certbot certonly --standalone --email 管理员邮箱 -d 申请证书的域名 -d 申请证书的域名`

# 续签 
`certbot renew` 会主动进行续签 


```bash
#!/bin/sh
# This script renews all the Let's Encrypt certificates with a validity < 30 days
if ! certbot renew > /var/log/letsencrypt/renew.log 2>&1 ; then
echo Automated renewal failed:
cat /var/log/letsencrypt/renew.log
exit 1
fi


#需要重启nginx证书才能生效
systemctl restart nginx

```
保存为bash脚本

添加crontab自动续签

```bash
0 23 28 * * /bin/sh 路径/certbotrenew.sh
```
每月28号23点执行


# nginx的配置模版

``` json
server{
    listen 80;
    server_name 域名;
    #告诉浏览器有效期内只准用 https 访问
    add_header Strict-Transport-Security max-age=15768000;
    #永久重定向到 https 站点
    return 301 https://$server_name$request_uri;
}
server {
   #启用 https, 使用 http/2 协议, nginx 1.9.11 启用 http/2 会有bug, 已在 1.9.12 版本中修复.
   listen 443 ssl http2;
   server_name 申请的域名;
   #首页
   index  index.php index.html index.htm;
   #网站根目录
   root   /usr/share/nginx/4spaces;
   #告诉浏览器当前页面禁止被frame
   add_header X-Frame-Options DENY;
   #告诉浏览器不要猜测mime类型
   add_header X-Content-Type-Options nosniff;
#证书路径
ssl_certificate /etc/letsencrypt/live/申请的域名/fullchain.pem;
#私钥路径
ssl_certificate_key /etc/letsencrypt/live/申请的域名/privkey.pem;
#安全链接可选的加密协议
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
#可选的加密算法,顺序很重要,越靠前的优先级越高.
ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
#在 SSLv3 或 TLSv1 握手过程一般使用客户端的首选算法,如果启用下面的配置,则会使用服务器端的首选算法.
ssl_prefer_server_ciphers on;
#储存SSL会话的缓存类型和大小
ssl_session_cache shared:SSL:10m;
#缓存有效期
ssl_session_timeout 60m;

location / {
    try_files $uri $uri/ /index.php?$args;  #修改内容
}

}
```
