#!/bin/bash

# Script para gestión de usuarios y copias de seguridad

# Verificación de existencia del archivo usuarios.csv
if [ ! -f "usuarios.csv" ]; then
    touch usuarios.csv
fi

# Función para generar el nombre de usuario
generauser() {
    nombre_usuario=$(echo "$1" | cut -c1 | tr '[:upper:]' '[:lower:]')
    apellido1=$(echo "$2" | cut -c1-3 | tr '[:upper:]' '[:lower:]')
    apellido2=$(echo "$3" | cut -c1-3 | tr '[:upper:]' '[:lower:]')
    dni=$(echo "$4" | grep -oE '[0-9]{8}[A-Za-z]' | tail -c 4)
    echo "${nombre_usuario}${apellido1}${apellido2}${dni:0:3}"
}

# Función para mostrar el menú
menu() {
    echo "Seleccione una opción:"
    echo "0.- LIMPIAR PANTALLA"
    echo "1.- EJECUTAR COPIA DE SEGURIDAD"
    echo "2.- DAR DE ALTA USUARIO"
    echo "3.- DAR DE BAJA AL USUARIO"
    echo "4.- MOSTRAR USUARIOS"
    echo "5.- MOSTRAR LOG DEL SISTEMA"
    echo "6.- SALIR"
}

# Función de copia de seguridad
copia() {
    backup_name="copia_usuarios_$(date +'%d%m%Y_%H-%M-%S').zip"
    zip "$backup_name" usuarios.csv
    # Limita a las dos copias de seguridad más recientes
    backups=( $(ls -t copia_usuarios_*.zip) )
    if [ ${#backups[@]} -gt 2 ]; then
        rm "${backups[2]}"
    fi
    echo "Copia de seguridad realizada: $backup_name" >> log.log
    sleep 1.5
}

# Función para dar de alta a un usuario
alta() {
    # Validar el nombre
    while true; do
        read -p "Nombre: " nombre
        if [[ "$nombre" =~ ^[a-zA-Z]+$ ]]; then
            break
        else
            echo "El nombre solo debe contener letras. Inténtalo de nuevo."
        fi
    done
    
    # Validar el primer apellido
    while true; do
        read -p "Apellido 1: " apellido1
        if [[ "$apellido1" =~ ^[a-zA-Z]+$ ]]; then
            break
        else
            echo "El primer apellido solo debe contener letras. Inténtalo de nuevo."
        fi
    done

    # Validar el segundo apellido
    while true; do
        read -p "Apellido 2: " apellido2
        if [[ "$apellido2" =~ ^[a-zA-Z]+$ ]]; then
            break
        else
            echo "El segundo apellido solo debe contener letras. Inténtalo de nuevo."
        fi
    done

    # Validar el DNI
    while true; do
        read -p "DNI (8 números y 1 letra): " dni
        if [[ "$dni" =~ ^[0-9]{8}[A-Za-z]$ ]]; then
            break
        else
            echo "El DNI debe contener 8 números seguidos de 1 letra. Inténtalo de nuevo."
        fi
    done
    
    nombre_usuario=$(generauser "$nombre" "$apellido1" "$apellido2" "$dni")
    
    if grep -q "^.*:.*:.*:.*:$nombre_usuario$" usuarios.csv; then
        echo "El usuario ya existe."
    else
        echo "$nombre:$apellido1:$apellido2:$dni:$nombre_usuario" >> usuarios.csv
        echo "INSERTADO $nombre:$apellido1:$apellido2:$dni:$nombre_usuario el $(date +'%d/%m/%Y a las %H:%M')" >> log.log
        echo "Usuario añadido: $nombre_usuario"
    fi
    sleep 1.5
}

# Función para dar de baja a un usuario
baja() {
    read -p "Nombre de usuario a eliminar: " nombre_usuario
    if grep -q "$nombre_usuario" usuarios.csv; then
        grep -v "$nombre_usuario" usuarios.csv > temp.csv && mv temp.csv usuarios.csv
        echo "BORRADO $nombre_usuario el $(date +'%d/%m/%Y a las %H:%M')" >> log.log
        echo "Usuario eliminado: $nombre_usuario"
    else
        echo "Usuario no encontrado."
    fi
    sleep 1.5
}

# Función para mostrar usuarios
mostrar_usuarios() {
    sort -t':' -k5 usuarios.csv | awk -F':' '{print $5 " - " $1 " " $2 " " $3 " (" $4 ")"}'
    sleep 1.5
}

# Función para mostrar el log
mostrar_log() {
    cat log.log
    sleep 1.5
}

# Función de login
login() {
    local intentos=3
    local usuario_valido=0
    while [ $intentos -gt 0 ]; do
        read -sp "Introduce tu nombre de usuario: " username
        echo
        if [ "$username" == "admin" ]; then
            usuario_valido=1
            break
        elif grep -q ":$username$" usuarios.csv; then
            usuario_valido=1
            break
        else
            ((intentos--))
            echo "Usuario no válido. Intentos restantes: $intentos"
        fi
    done

    if [ $usuario_valido -eq 0 ]; then
        echo "No se ha podido iniciar sesión."
        exit 1
    fi
}

# Llamada a la función de login antes de mostrar el menú
login

# Ejecución del menú
while true; do
    menu
    read -p "Seleccione una opción: " opcion
    case $opcion in
        0) clear ;;
        1) copia ;;
        2) alta ;;
        3) baja ;;
        4) mostrar_usuarios ;;
        5) mostrar_log ;;
        6) 
            echo "Cerrando el programa..."
            sleep 2
            break ;;  # Usamos break para que se salga del programa y no cierre la terminal
        *) echo "Opción no válida. Intente de nuevo." ;;
    esac
done

