#!/bin/bash

# Папка, куда будем складывать архивы
backup_dir="/backup2/"

# Имя сервера, который архивируем
srv_name="nodeOne"

# Адрес сервера, который архивируем
srv_ip="192.168.56.30"

# Пользователь rsync на сервере, который архивируем
srv_user="backupuser"

# Ресурс на сервере для бэкапа
srv_dir="data"

# Текущая дата и время
current_date=$(date +%Y-%m-%d_%H-%M-%S)

# Полная резервная копия (воскресенье)
if [[ $(date +%u) -eq 7 ]]; then
    backup_type="full"
else
    # Инкрементная копия (будний день)
    if [[ $(date +%u) -le 5 ]]; then
        backup_type="incremental"
    else
        # Дифференциальная копия (конец дня)
        backup_type="differential"
    fi
fi

echo "Start backup ${srv_name} (${backup_type}) - ${current_date}"

# Создаем папку для текущего бэкапа
mkdir -p "${backup_dir}${srv_name}/${backup_type}/${current_date}"

# Выполняем резервное копирование
rsync -avz --progress --delete --password-file=/etc/rsyncd.scrt \
    "${srv_user}@${srv_ip}::${srv_dir}" \
    "${backup_dir}${srv_name}/${backup_type}/${current_date}/"

# Удаляем старые инкрементные копии (старше 14 дней)
if [[ ${backup_type} == "incremental" ]]; then
    find "${backup_dir}${srv_name}/incremental/" -maxdepth 1 -type d -mtime +14 -exec rm -rf {} \;
fi

# Удаляем старые дифференциальные копии (старше 7 дней)
if [[ ${backup_type} == "differential" ]]; then
    find "${backup_dir}${srv_name}/differential/" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;
fi

echo "Finish backup ${srv_name} (${backup_type}) - ${current_date}"
