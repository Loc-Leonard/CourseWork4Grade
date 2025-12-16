# CourseWork4Grade — VoIP стенд (Issabel + baresip) на Vagrant

## Описание проекта
Этот репозиторий разворачивает учебный VoIP‑стенд в **VirtualBox** под управлением **Vagrant**: одна виртуальная машина с Issabel (Asterisk/PJSIP) и две виртуальные машины с SIP‑клиентами baresip, которые регистрируются в Issabel как внутренние абоненты 101/102/103.  
Развёртывание выполняется автоматически с помощью shell‑провижининга из каталога `scripts/`, описанного в `Vagrantfile`.

---

## Используемые технологии
- **Vagrant** — управление жизненным циклом виртуальных машин, сетями и провижинингом.  
- **VirtualBox** — провайдер виртуализации для Vagrant.  
- **Issabel 4 / Asterisk / PJSIP** — IP‑АТС, принимающая регистрации от клиентов и маршрутизирующая вызовы.  
- **baresip** — лёгкий SIP user‑agent, запускаемый в нескольких профилях (101/102/103).   
- **Bash‑скрипты** — автоматизация установки и настройки компонентов.

---

## Подготовка хост‑машины

1. Установить **VirtualBox** (актуальная версия для вашей ОС).  
2. Установить **Vagrant**. 
3. Проверить, что инструменты доступны из терминала:
vagrant --version
VBoxManage --version


Box’ы Vagrant завязаны на конкретный провайдер: VirtualBox‑box работает с VirtualBox‑provider.

---

## Создание Issabel box для Vagrant

Проект предполагает, что у вас есть локальный `box` с Issabel. Его можно собрать из уже установленной VM в VirtualBox с помощью `vagrant package`.

### 1. Установить Issabel в VirtualBox
- Создать новую VM в VirtualBox.  
- Установить Issabel 4 с официального ISO (обычная установка).  
- Задать VM понятное имя, например `issabel-4-vagrant` — оно понадобится для упаковки.

### 2. Подготовить Issabel под требования Vagrant
Внутри Issabel‑VM выполнить базовую подготовку “base box”:

- Создать пользователя `vagrant`.  
- Выдать ему `sudo` без пароля (правило в `/etc/sudoers`).  
- Настроить SSH‑доступ по ключу (добавить публичный ключ в `~vagrant/.ssh/authorized_keys`).  

Это позволяет Vagrant выполнять `vagrant ssh` и провижининг без ручного ввода паролей.

### 3. Упаковать VM в `.box`
На хост‑машине (Issabel‑VM должна быть выключена):

vagrant package --base "issabel-4-vagrant" --output issabel-4-virtualbox.box



### 4. Добавить box в локальный каталог Vagrant
vagrant box add issabel-4 ./issabel-4-virtualbox.box



Теперь `issabel-4` можно использовать как `config.vm.box` в `Vagrantfile`.

---

## Особенности работы baresip и портов

В одной course‑VM запускаются несколько экземпляров baresip. Важно учитывать, что `sip_listen` в baresip открывает не только UDP/TCP на указанном порту, но и TLS‑листенер на порту `+1`. Из‑за этого использование соседних портов приводит к ошибке `Address already in use`. 

Рекомендуемая схема портов для профилей:
- **101**: `sip_listen 0.0.0.0:5101` (TLS займет 5102).   
- **102**: `sip_listen 0.0.0.0:5103` (TLS займет 5104).   
- **103**: `sip_listen 0.0.0.0:5105` (TLS займет 5106).   

Это уже учтено в скриптах `phone_course*` в каталоге `scripts/`.

---

## Быстрый старт

1. Добавить локальный box Issabel (пример):
vagrant box add issabel-4 ./boxes/issabel-4-virtualbox.box


2. В корне репозитория выполнить:
vagrant up


Vagrant поднимет Issabel и course‑ВМ и запустит соответствующие скрипты из `scripts/`.
3. Проверить регистрации на Issabel:
vagrant ssh issabel
sudo asterisk -rvvvvv

pjsip show endpoints
pjsip show contacts
pjsip show aor 101


Команда `pjsip show aor 101` показывает, привязан ли к AOR 101 активный контакт (динамическая регистрация).

---

## Структура репозитория

```text
vagrant_VM/
├── .vagrant/                  # Служебные файлы Vagrant (создаются автоматически)
├── scripts/                   # Скрипты провижининга VM
│   ├── phone_course-1.sh      # Настройка первой course-VM с SIP-клиентами
│   ├── phone_course-2.sh      # Настройка второй course-VM с SIP-клиентами
│   ├── provision-issabel.sh   # Настройка VoIP-сервера (Issabel/Asterisk) на Ubuntu
│   └── provision.sh           # Общий оркестратор провижининга, вызываемый из Vagrantfile
├── issabel-sourse.box         # Локальный box/образ Issabel (используется как base box)
├── REME.md                    # Документация проекта (README)
├── Vagrantfile                # Описание виртуальных машин, сетей и сценариев провижининга
└── .gitignore                 # Настройки игнорирования файлов Git```
Основные файлы и каталоги:

### `Vagrantfile`
Главный файл Vagrant. Описывает:

- Набор виртуальных машин (Issabel и course‑ВМ).  
- Сетевые интерфейсы и IP‑адреса.  
- Подключение shell‑провижининга через `config.vm.provision "shell", path: "scripts/provision.sh"` или отдельные скрипты.

Этот файл — точка входа для `vagrant up` и `vagrant halt/destroy`.

### `scripts/`
Каталог со всеми bash‑скриптами, которые выполняет Vagrant.

#### `scripts/provision.sh`
Главный скрипт‑оркестратор:

- Определяет роль машины (Issabel / course‑VM) по имени или окружению.  
- Запускает соответствующие скрипты: настройку Issabel и/или настройку baresip.

#### `scripts/provision-issabel*.sh`
Скрипты настройки Issabel:

- Создают или обновляют конфигурацию PJSIP (AOR, Auth, Endpoint) для абонентов 101/102/103.  
- Настраивают endpoint’ы так, чтобы идентификация REGISTЕR шла по username из SIP (`identify_by=username,ip`), что предотвращает ошибки вида `No matching endpoint found`.  
- Выполняют `asterisk -rx "pjsip reload"` для применения изменений. 

#### `scripts/phone_course*.sh`
Скрипты настройки course‑машин с baresip:

- Устанавливают baresip через пакетный менеджер.  
- Создают отдельные профили: `~/.baresip-101`, `~/.baresip-102`, `~/.baresip-103`.  
- Прописывают:
- `sip_listen` на уникальных портах (5101/5103/5105) с учётом TLS `+1`.   
- `net_interface` (обычно `eth1`) и `net_af ipv4`.  
- Файлы `accounts` с SIP‑аккаунтами, указывающими на Issabel (логин 101/102/103, пароли, `regint`). 

### `issabel-sourse*`
Вспомогательный файл (или набор файлов) с заметками по Issabel:

- Источники ISO.  
- Дополнительные команды для диагностики.  
- Варианты ручной настройки.  

Этот файл играет роль расширенной документации/черновика и дополняет краткое описание в README.

---

## Отладка

### SIP‑лог на Issabel
Для анализа регистраций и вызовов включите логгер PJSIP:  
pjsip set logger on


Это позволит видеть входящие REGISTER, ответы 401/200 и выбор endpoint’ов Asterisk’ом. 

### Ошибки портов baresip
Если при запуске нескольких профилей baresip появляется `Address already in use`, проверьте:

- Порты `sip_listen` действительно различаются минимум на 2 (5101, 5103, 5105, …).   
- Нет ли “висящих” процессов baresip:
pgrep -a baresip



После правок конфигурации baresip перезапустите соответствующий профиль.

---