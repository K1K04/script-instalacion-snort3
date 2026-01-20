#!/bin/bash
# Script para instalar Snort 3 correctamente en Debian 12
# Ejecutar como root

set -e

echo "=== Limpiando instalaciones previas ==="
rm -rf /tmp/libdaq* /tmp/snort3* /tmp/daq-*

echo "=== Instalando dependencias completas ==="
apt update
apt install -y build-essential cmake libpcap-dev libpcre3-dev libdumbnet-dev \
    bison flex zlib1g-dev liblzma-dev libssl-dev libnghttp2-dev wget \
    pkg-config libhwloc-dev libluajit-5.1-dev libunwind-dev \
    libmnl-dev libnfnetlink-dev libnetfilter-queue-dev git \
    autoconf libtool libpcre2-dev

echo "=== Descargando e instalando libDAQ 3.0.15 (compatible con Snort 3) ==="
cd /tmp
wget https://github.com/snort3/libdaq/archive/refs/tags/v3.0.15.tar.gz -O libdaq-3.0.15.tar.gz
tar -xvzf libdaq-3.0.15.tar.gz
cd libdaq-3.0.15
./bootstrap
./configure
make -j$(nproc)
make install

echo "=== Actualizando ldconfig ==="
echo "/usr/local/lib" > /etc/ld.so.conf.d/snort.conf
ldconfig

echo "=== Descargando e instalando Snort 3.1.75.0 ==="
cd /tmp
wget https://github.com/snort3/snort3/archive/refs/tags/3.1.75.0.tar.gz -O snort3-3.1.75.0.tar.gz
tar -xvzf snort3-3.1.75.0.tar.gz
cd snort3-3.1.75.0

echo "=== Configurando Snort 3 correctamente ==="
./configure_cmake.sh --prefix=/usr/local/snort

# Crear carpeta build y compilar
mkdir -p build
cd build
echo "=== Compilando Snort 3 (esto puede tardar varios minutos) ==="
make -j$(nproc)
make install

echo "=== Creando enlace simbólico ==="
ln -sf /usr/local/snort/bin/snort /usr/sbin/snort

echo "=== Creando estructura de directorios ==="
mkdir -p /etc/snort/rules
mkdir -p /var/log/snort
mkdir -p /usr/local/snort/etc/snort

echo "=== Creando usuario y grupo snort ==="
groupadd snort 2>/dev/null || true
useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort 2>/dev/null || true

echo "=== Configurando permisos ==="
chown -R snort:snort /var/log/snort
chmod -R 775 /var/log/snort

echo "=== Actualizando PATH ==="
echo 'export PATH=$PATH:/usr/local/snort/bin' >> /root/.bashrc
export PATH=$PATH:/usr/local/snort/bin

echo ""
echo "=========================================="
echo "=== INSTALACIÓN COMPLETADA ==="
echo "=========================================="
echo ""
/usr/local/snort/bin/snort -V
echo ""
echo "Próximos pasos:"
echo "1. Crear /usr/local/snort/etc/snort/snort.lua (configuración principal)"
echo "2. Crear /etc/snort/rules/mis_reglas.rules (tus reglas personalizadas)"
echo "3. Ejecutar: snort -c /usr/local/snort/etc/snort/snort.lua"
echo ""
echo "NOTA: Snort 3 usa sintaxis LUA, no .conf"
echo ""
