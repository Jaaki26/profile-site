# Build stage not required for plain static; we copy directly into nginx
FROM nginx:stable-alpine
COPY app/ /usr/share/nginx/html/
# optional: custom nginx config
# COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
