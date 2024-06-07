# Nagios Core Docker Image

## Descripción

Este proyecto proporciona una imagen Docker para Nagios Core, configurada para ejecutarse automáticamente y estar accesible a través del puerto 80. La imagen incluye todas las dependencias necesarias para que Nagios funcione correctamente.

## Prerrequisitos

- Una cuenta de AWS y acceso a una instancia EC2.
- Docker instalado en la instancia EC2.
- Acceso a GitHub para subir el código.

## Instrucciones

### Paso 1: Crear y Editar el Dockerfile

1. **Navegar al Directorio de Trabajo**

   - Crear un nuevo directorio para el proyecto y navegar a él:
     ```bash
     mkdir ~/nagios-docker
     cd ~/nagios-docker
     ```

2. **Crear el Dockerfile**

   - Crear un nuevo archivo `Dockerfile`:
     ```bash
     nano Dockerfile
     ```

3. **Escribir el Contenido del Dockerfile**

   - Añadir el siguiente contenido al `Dockerfile` y guardar los cambios:
     ```Dockerfile
     # Usar la imagen base de Ubuntu más reciente
     FROM ubuntu:latest

     # Información del mantenedor
     LABEL maintainer="vi.liberona@duocuc.cl"

     # Configurar el entorno para evitar interacciones
     ENV DEBIAN_FRONTEND=noninteractive

     # Actualizar los paquetes e instalar las dependencias necesarias para Nagios
     # - wget: Utilidad para descargar archivos desde la web
     # - build-essential: Herramientas de desarrollo esenciales
     # - unzip: Utilidad para descomprimir archivos zip
     # - apache2: Servidor web Apache
     # - php: Lenguaje de scripting para el servidor web
     # - libapache2-mod-php: Módulo PHP para Apache
     # - libgd-dev: Biblioteca para la manipulación de gráficos
     # - libperl-dev: Biblioteca Perl para el desarrollo
     # - libssl-dev: Biblioteca SSL para seguridad
     # - daemon: Utilidad para administrar procesos de fondo
     # - iputils-ping: Herramienta para verificar la conectividad de la red
     RUN apt-get update && \
         apt-get install -y wget build-essential unzip apache2 php libapache2-mod-php libgd-dev libperl-dev libssl-dev daemon iputils-ping

     # Crear usuario y grupo para Nagios y asignar permisos
     # - Crea el usuario 'nagios'
     # - Crea el grupo 'nagcmd'
     # - Añade el usuario 'nagios' al grupo 'nagcmd'
     # - Añade el usuario 'www-data' (utilizado por Apache) al grupo 'nagcmd'
     RUN useradd nagios && \
         groupadd nagcmd && \
         usermod -aG nagcmd nagios && \
         usermod -aG nagcmd www-data

     # Descargar y descomprimir Nagios Core
     # - Descarga el archivo tar.gz de Nagios Core
     # - Descomprime el archivo descargado
     RUN wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.5.2.tar.gz && \
         tar -zxvf nagios-4.5.2.tar.gz

     # Configurar, compilar e instalar Nagios Core
     # - Cambia al directorio descomprimido de Nagios
     # - Ejecuta el script de configuración con el grupo de comandos
     # - Compila el código fuente de Nagios
     # - Instala Nagios, incluyendo los scripts de inicio y configuración
     RUN cd nagios-4.5.2 && \
         ./configure --with-command-group=nagcmd > configure.log 2>&1 || { cat configure.log; exit 1; } && \
         make all > make_all.log 2>&1 || { cat make_all.log; exit 1; } && \
         make install > make_install.log 2>&1 || { cat make_install.log; exit 1; } && \
         make install-init && \
         make install-config && \
         make install-commandmode && \
         make install-webconf

     # Descargar, configurar e instalar los plugins de Nagios
     # - Descarga el archivo tar.gz de los plugins de Nagios
     # - Descomprime el archivo descargado
     # - Configura los plugins para que utilicen el usuario y grupo 'nagios'
     # - Compila e instala los plugins de Nagios
     RUN wget https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz && \
         tar -zxvf nagios-plugins-2.3.3.tar.gz && \
         cd nagios-plugins-2.3.3 && \
         ./configure --with-nagios-user=nagios --with-nagios-group=nagios > configure_plugins.log 2>&1 || { cat configure_plugins.log; exit 1; } && \
         make > make_plugins.log 2>&1 || { cat make_plugins.log; exit 1; } && \
         make install > make_install_plugins.log 2>&1 || { cat make_install_plugins.log; exit 1; }

     # Configurar la autenticación y activar comandos externos en Nagios
     # - Crea un archivo de contraseñas para 'nagiosadmin' con la contraseña 'nagios'
     # - Modifica la configuración de Nagios para permitir comandos externos
     RUN htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagios && \
         sed -i 's/^check_external_commands=0/check_external_commands=1/' /usr/local/nagios/etc/nagios.cfg

     # Habilitar el módulo CGI en Apache y configurar el servidor
     # - Activa el módulo CGI para la ejecución de scripts
     # - Añade 'ServerName localhost' a la configuración de Apache para evitar advertencias
     RUN a2enmod cgi && \
         echo "ServerName localhost" >> /etc/apache2/apache2.conf

     # Crear y configurar el script de inicio para Nagios
     # - Crea un script para iniciar Apache y Nagios, y mantener el contenedor en ejecución
     # - Establece permisos de ejecución para el script
     RUN echo '#!/bin/bash\n\
     trap "exit" SIGINT SIGTERM\n\
     service apache2 start\n\
     /usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg\n\
     tail -f /usr/local/nagios/var/nagios.log' > /start.sh && \
         chmod +x /start.sh
### Paso 2: Construir la Imagen Docker

1. **Construir la Imagen**

   - Desde el directorio donde están tus archivos, ejecutar:
     ```bash
     sudo docker build -t nagios-core .
     ```

2. **Verificar que la Imagen se ha Construido**

   - Listar las imágenes Docker para verificar que `nagios-core` se ha creado:
     ```bash
     sudo docker images
     ```

### Paso 3: Probar la Imagen Localmente

1. **Ejecutar el Contenedor**

   - Ejecutar la imagen para verificar que funciona:
     ```bash
     sudo docker run -d -p 80:80 nagios-core
     ```

2. **Verificar Acceso**

   - Abrir el navegador y navegar a la IP pública de la instancia EC2:
     ```text
     http://54.82.219.107/nagios
     ```

### Notas y Consideraciones

- **Verificar las Dependencias**: Asegurarse de que todas las dependencias de Nagios están instaladas correctamente. El `Dockerfile` instala las más comunes, pero se puede ajustar según las necesidades específicas.
- **Ajustes de Seguridad**: Este Dockerfile crea un usuario `nagiosadmin` con contraseña `nagios`. Cambiar esta configuración en producción para asegurar la instalación.

     # Exponer los puertos 80 y 443 para HTTP y HTTPS
     EXPOSE 80 443

     # Definir el comando para iniciar el contenedor utilizando el script de inicio
     CMD ["/start.sh"]
     ```
