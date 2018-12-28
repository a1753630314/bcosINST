FROM  mysql/mysql-server:5.7
COPY ./bcos_browser_table.sql /docker-entrypoint-initdb.d
COPY ./bcos_browser_tableV.sql /docker-entrypoint-initdb.d
COPY ./proc.sql /docker-entrypoint-initdb.d
ENV MYSQL_ROOT_PASSWORD="123456"
ENV MYSQL_DATABASE="bcos_browser"
ENV MYSQL_USER="test"
ENV MYSQL_PASSWORD="123456"
ENV MYSQL_ROOT_HOST="%"
EXPOSE 3306