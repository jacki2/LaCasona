FROM php:8.2-apache

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Configurar y compilar extensiones de PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        pdo \
        pdo_mysql \
        mbstring \
        xml \
        zip \
        opcache

# Habilitar módulos de Apache
RUN a2enmod rewrite headers

# Configurar PHP para producción
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Configurar límites de PHP
RUN { \
    echo 'upload_max_filesize=50M'; \
    echo 'post_max_size=50M'; \
    echo 'memory_limit=256M'; \
    echo 'max_execution_time=300'; \
    echo 'max_input_vars=3000'; \
    echo 'date.timezone=America/Lima'; \
} > /usr/local/etc/php/conf.d/custom.ini

# Copiar configuración personalizada de Apache
COPY devops/apache/000-default.conf /etc/apache2/sites-available/000-default.conf

# Copiar archivo .htaccess
COPY devops/htaccess/.htaccess /var/www/html/.htaccess

# Copiar contenido del proyecto
COPY ./Interfaz/ /var/www/html/

# Crear estructura de carpetas necesarias
RUN mkdir -p /var/www/html/assets/css \
    /var/www/html/assets/js \
    /var/www/html/assets/imagenes \
    /var/www/html/controllers \
    /var/www/html/includes \
    /var/www/html/admin

# Asignar permisos
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/assets

# Crear usuario no-root (opcional)
RUN groupadd -r kawai && useradd -r -g kawai kawai

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Exponer puerto HTTP
EXPOSE 80

# Comando por defecto
CMD ["apache2-foreground"]
