# Домашнее задание дисковая подсистема

Делаем fork репозитория и клонируем его:
```
git clone https://github.com/mashchensky/otus-linux
```
Переходим в созданную директорию:
```
cd otus-linux/
```
Добавляем в Vagrantfile еще один диск:
```
:sata5 => {
        :dfile => './sata5.vdi',
        :size => 250, # Megabytes
        :port => 5
}
```
Запустим ВМ и зайдем в нее:
```
vagrant up
vagrant ssh
```
Проверяем созданные диски:
```
[vagrant@otuslinux ~]$ sudo lshw -short | grep disk
/0/100/1.1/0.0.0    /dev/sda   disk        42GB VBOX HARDDISK
/0/100/d/0          /dev/sdb   disk        262MB VBOX HARDDISK
/0/100/d/1          /dev/sdc   disk        262MB VBOX HARDDISK
/0/100/d/2          /dev/sdd   disk        262MB VBOX HARDDISK
/0/100/d/3          /dev/sde   disk        262MB VBOX HARDDISK
/0/100/d/0.0.0      /dev/sdf   disk        262MB VBOX HARDDISK
```
Занулим суперблоки:
```
sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
```
Создаем рейд 5 из 5 дисков:
```
sudo mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}
```
Проверим, что рейд собрался правильно:
```
[vagrant@otuslinux ~]$ cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdf[5] sde[3] sdd[2] sdc[1] sdb[0]
      1015808 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/5] [UUUUU]
[vagrant@otuslinux ~]$ sudo mdadm -D /dev/md0
```
Для создания mdadm.conf убедимся, что информация верна:
```
[vagrant@otuslinux ~]$ sudo mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid5 num-devices=5 metadata=1.2 name=otuslinux:0 UUID=0843ad41:f3aeeab8:0e40f429:216045ad
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf
```
Затем создадим файл mdadm.conf:
```
mkdir /etc/mdadm/
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```

Искусственно "зафейлим" одно из устройств:
```
mdadm /dev/md0 --fail /dev/sde
```
Проверим как это отобразилось на рейде:
```
[vagrant@otuslinux ~]$ cat /proc/mdstat 
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdf[5] sde[3](F) sdd[2] sdc[1] sdb[0]
      1015808 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/4] [UUU_U]
```
Удалим сломанный диск:
```
mdadm /dev/md0 --remove /dev/sde
```
Добавим диск заново:
```
mdadm /dev/md0 --add /dev/sde
```
Процесс ребилда можно посмотреть:
```
cat /proc/mdstat
mdadm -D /dev/md0
```

Создадим GPT на RAID:
```
parted -s /dev/md0 mklabel gpt
```
Создадим партиции:
```
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
```
Создаем на партициях ФС:
```
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
```
И монтируем их по каталогам:
```
sudo mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do sudo mount /dev/md0p$i /raid/part$i; done
```

