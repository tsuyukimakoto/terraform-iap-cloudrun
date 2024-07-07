FROM nginx:alpine

COPY ./src /usr/share/nginx/html

EXPOSE 8080
CMD sed -i 's/listen\s*80;/listen '"8080"';/' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'