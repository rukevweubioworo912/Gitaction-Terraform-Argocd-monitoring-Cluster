
FROM nginx:alpine


WORKDIR /usr/share/nginx/html


RUN rm -rf /usr/share/nginx/html/*


COPY ./app/index.html /usr/share/nginx/html/
COPY ./app/nginx.conf /etc/nginx/nginx.conf


EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
