FROM ubuntu:latest

LABEL maintainer="vi.liberona@duocuc.cl"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y wget build-essential unzip apache2 php libapache2-mod-php libgd-dev libperl-dev libssl-dev daemon iputils-ping
RUN useradd nagios && \
    groupadd nagcmd && \
    usermod -aG nagcmd nagios && \
    usermod -aG nagcmd www-data
RUN wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.5.2.tar.gz && \
    tar -zxvf nagios-4.5.2.tar.gz
RUN cd nagios-4.5.2 && \
    ./configure --with-command-group=nagcmd > configure.log 2>&1 || { cat configure.log; exit 1; } && \
    make all > make_all.log 2>&1 || { cat make_all.log; exit 1; } && \
    make install > make_install.log 2>&1 || { cat make_install.log; exit 1; } && \
    make install-init && \
    make install-config && \
    make install-commandmode && \
    make install-webconf
RUN wget https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz && \
    tar -zxvf nagios-plugins-2.3.3.tar.gz && \
    cd nagios-plugins-2.3.3 && \
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios > configure_plugins.log 2>&1 || { cat configure_plugins.log; exit 1; } && \
    make > make_plugins.log 2>&1 || { cat make_plugins.log; exit 1; } && \
    make install > make_install_plugins.log 2>&1 || { cat make_install_plugins.log; exit 1; }
RUN htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagios && \
    sed -i 's/^check_external_commands=0/check_external_commands=1/' /usr/local/nagios/etc/nagios.cfg
RUN a2enmod cgi && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN echo '#!/bin/bash\n\
trap "exit" SIGINT SIGTERM\n\
service apache2 start\n\
/usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg\n\
tail -f /usr/local/nagios/var/nagios.log' > /start.sh && \
    chmod +x /start.sh
EXPOSE 80 443
CMD ["/start.sh"]
