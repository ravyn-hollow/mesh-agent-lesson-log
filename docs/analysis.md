# Технический разбор пакета `mesh-agent-lesson-log` (МОС)

Дата разбора: 30.10.2026. Разбор статический, демон не запускался.

## Артефакты

| Файл | SHA-256 |
|---|---|
| `mesh-agent-lesson-log-0.1.3-1.git84da32.2.x86_64.rpm` | `d886675a18a5db56fcee4fdcc6535c5e91c5a0571ea7ccc0b58abb79519b0b72` |
| `mesh-agent-lesson-log-1.1.0-2.gitea3ac2.1.x86_64.rpm` | `3ebf32f8bd899c8da7bed3ef5fc75f0b3d2135a153397735e99dcaabf9bd91ad` |

Ссылка на скачивание 1.1.0 с сервера ДИТ (доступна только с российских IP):
`https://mostech-cloud.mos.ru/s/jbDEPLme3QKLSfG/download/mesh-agent-lesson-log-1.1.0-2.gitea3ac2.1.x86_64.rpm`
(формат `/s/<token>/download` — шаринг файла в облачном сервисе `mostech-cloud.mos.ru`.)

## Краткие выводы

Пакет `mesh-agent-lesson-log` — агент звукозаписи уроков для компьютеров под управлением
МОС («Московская электронная школа», дистрибутив на базе Росы). Он:

1. работает как systemd-демон от пользователя `mesh-agent` с группой `audio`,
   автозапуск включён пресетом при установке;
2. опрашивает сервер получения заданий (в 0.1.3 — каждые 30 секунд);
3. записывает звук из аудитории через `arecord` (WAV → OPUS через `ffmpeg`),
   умеет самостоятельно размьютить микрофон (`temporaryUnmute`, `readMuteState`);
4. отправляет записанные файлы на SMB-шару `MEDIASTG` (порт 445; сервер загрузки стоит
   в школьном здании, управляет им ДИТ) и/или на HTTP-эндпоинт
   загрузки (`multipart/form-data`, поля `file` и `metadata`);
5. удаляет локальные записи после успешной отправки
   (`keep-success-hours: 24`, лог `cleanup: job=%s deleted`).

Пакет отсутствует в публичном репозитории МОС; распространяется установкой локального
rpm-файла (с сервера `mostech-cloud.mos.ru`).

## Метаданные пакетов

Оба собраны в инфраструктуре ROSA/ABF (Vendor: ROSA, Bug URL: bugzilla.rosa.ru),
исходники: `https://hub.mos.ru/mos/cloudcom/mesh-agent` — внутренний Gitea ДИТ.

### 0.1.3 (подписан)

```
Version     : 0.1.3
Release     : 1.git84da32.2        DistTag: rosa13
Build Date  : Сб 18 июл 2026 17:56:31
Build Host  : mos-hz6phq
License     : Proprietary
Signature   : EdDSA/SHA256, Сб 18 июл 2026 17:59:03, Key ID 507eea45722f23cd
Summary     : Агент для аудиозаписи урока
Description : Автономный агент записи для MOS Panel.
              Агент записывает аудио из аудитории, сообщает о статусе
              и загружает полученный аудиофайл.
```

`rpm -K`: `digests signatures ОК`. Key ID `507eea45722f23cd` — последние 8 байт
отпечатка `F307F3F0F3EB3B9CA9EC4EF2507EEA45722F23CD`, то есть пакет подписан
ключом сборочной системы `abf@os.mos.ru` (той же подписью, что и публичные
пакеты МОС).

**Источник ключа и независимая проверка.** Ключ официально распространяется самой
МОС: пакет `mostech-repos-keys-2021.1-5-rosa2021.1.noarch.rpm` из официального
репозитория `https://os.mos.ru/repo/mos2021.1/x86_64/main/release/` содержит единственный
файл `/etc/pki/rpm-gpg/RPM-GPG-KEY-MOS`:

```
pub   ed25519 2025-11-07 [SC]
      F307F3F0F3EB3B9CA9EC4EF2507EEA45722F23CD
uid   abf.mos.ru <abf@os.mos.ru>
```

(пакет `mos-repos-keys-2021.1-5` из того же репозитория содержит другой ключ —
`RPM-GPG-KEY-ROSA`, `rsa2048`, `C3FE0B0A…16A853E7`, `Repo Team <alex.burmashev@rosalab.ru>`;
к подписи отношения не имеет.)

Проверка выполнена в чистой rpm-базе без каких-либо заранее установленных ключей —
только с импортированным `RPM-GPG-KEY-MOS`:

```bash
mkdir /tmp/clean-rpmdb
rpm --dbpath /tmp/clean-rpmdb --import RPM-GPG-KEY-MOS
rpm --dbpath /tmp/clean-rpmdb -K mesh-agent-lesson-log-0.1.3-1.git84da32.2.x86_64.rpm
# digests signatures ОК
rpm --dbpath /tmp/clean-rpmdb -K mesh-agent-lesson-log-1.1.0-2.gitea3ac2.1.x86_64.rpm
# digests ОК  (подписи нет)
```

Вывод: подпись 0.1.3 проходит исключительно официальным доверенным ключом МОС,
который система получает по умолчанию.

### 1.1.0 (НЕ подписан)

```
Version     : 1.1.0
Release     : 2.gitea3ac2.1       DistTag: rosa2021.1
Build Date  : Пт 09 окт 2026 13:35:49
Build Host  : mos-nd2jsf
License     : Proprietary
Signature   : (none)
Summary     : Агент обеспечивает проведение урока
Description : Системный агент для МОС (Операционная система
              «Московской электронной школы»).
              Агент обеспечивает проведение урока.
```

`rpm -K`: `digests ОК` — подписи нет. Описание между версиями изменено:
из «Агент для аудиозаписи урока / записывает аудио из аудитории» — в нейтральное
«Агент обеспечивает проведение урока». Функциональность записи при этом сохранена
и развита (см. ниже). Наличие обеих версий показывает эволюцию: июльская сборка
описана откровенно, октябрьская — замаскирована.

### Сравнение 0.1.3 → 1.1.0

| | 0.1.3 (июль 2026) | 1.1.0 (октябрь 2026) |
|---|---|---|
| Подпись | есть — EdDSA, ключ `abf@os.mos.ru` | **удалена** (`Signature: (none)`) |
| Summary | «Агент для аудиозаписи урока» | «Агент обеспечивает проведение урока» |
| Description | «Агент записывает аудио из аудитории…» | «Агент обеспечивает проведение урока» |
| Запись звука | есть | есть, **добавлено снятие mute** |
| Уведомление на рабочий стол | есть (`kde-notify`) | удалено |
| Сервер заданий | HTTP, IP Selectel, опрос 30 с | HTTPS, `school.mos.ru/api/speech-analytics`, опрос 600 с |

Удаление подписи: `rpm -K` возвращает только `digests ОК` (дайджесты содержимого),
без `signatures` — пакет 1.1.0 не проходит штатную проверку целостности. В сочетании
с изменением описания (то, что видит администратор при установке) и сохранением/расширением
функции записи это согласуется с намерением сделать пакет менее заметным. Удаление
подписи само по себе не доказывает умысла (может быть следствием сборки вне штатного
конвейера), но в совокупности ставит вопросы, требующие официальных разъяснений.

## Состав пакета

```
/etc/mesh-agent/config.json                                    — конфигурация
/usr/bin/mesh-agent-lesson-log                                 — демон (Go, stripped)
/usr/lib/systemd/system/mesh-agent-lesson-log.service          — systemd-юнит
/usr/lib/systemd/system-preset/90-mesh-agent-lesson-log.preset — «enable» (автозапуск)
/usr/lib/sysusers.d/mesh-agent-lesson-log.conf                 — пользователь mesh-agent
/usr/libexec/mesh-agent-lesson-log/kde-notify                  — только в 0.1.3
/usr/share/doc/mesh-agent-lesson-log/README.md                 — документация
/var/lib/cloudcom/agent/{jobs,tmp}                             — каталоги записей
```

systemd-юнит (обе версии, отличия — только в пути и описании):

```ini
[Unit]
Description=CloudCom lesson log mesh agent        # 1.1.0: CloudCom lesson delivery agent
After=network-online.target sound.target
Wants=network-online.target

[Service]
User=mesh-agent
Group=mesh-agent
SupplementaryGroups=audio
WorkingDirectory=/var/lib/cloudcom/agent
ExecStart=/usr/bin/mesh-agent-lesson-log
Restart=always
RestartSec=10
StateDirectory=cloudcom/agent
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

Пользователь `mesh-agent` создаётся через sysusers (`/sbin/nologin`), группа `audio`
даёт доступ к записывающим устройствам. Скрипты установки стандартные (systemd),
`%post` включает юнит через systemd-update-helper.

## Конфигурация (`/etc/mesh-agent/config.json`)

### 0.1.3

```json
{
  "backend": {
    "base-url": "http://82.148.29.56:18080/cloudcom/listener-server/api/v1/agent",
    "sync-interval-seconds": 30,
    "timeout-seconds": 30
  },
  "samba": { "ip-address": "MEDIASTG", "port": 445, "share-name": "in" },
  "recording": {
    "root-dir": "/var/lib/cloudcom/agent/jobs",
    "temp-dir": "/var/lib/cloudcom/agent/tmp",
    "audio-format": "OPUS", "channels": 1,
    "sample-rate": 44100, "sample-format": 2,
    "keep-success-hours": 24
  },
  "upload": { "target": "NETWORK_SHARE" }
}
```

`82.148.29.56` — whois: `SELECTEL-NET` (Selectel, Санкт-Петербург,
 Cvetochnaya st. 21). Опрос каждые 30 секунд, открытым HTTP.

### 1.1.0

```json
{
  "backend": {
    "base-url": "https://school.mos.ru/api/speech-analytics/internal/v1/agent",
    "sync-interval-seconds": 600,
    "timeout-seconds": 30
  },
  "samba": { "ip-address": "MEDIASTG.", "port": 445, "share-name": "in" },
  "recording": { ... то же ... },
  "upload": { "target": "NETWORK_SHARE" }
}
```

Эндпоинт переехал с IP Селектела на публичный домен `school.mos.ru`, в URL появился
сегмент `speech-analytics` («речевая аналитика»). README 1.1.0 прямо называет
production endpoint и API-ключ:

```
https://school.mos.ru/api/speech-analytics/internal/v1/agent/sync
Production API key 80f594fd-72d5-4a3a-8945-89a475d941df встроен в бинарный файл.
```

Ключ подтверждён поиском в бинарнике 1.1.0 (строка `80f594fd-72d5-4a3a-8945-89a475d941df`,
заголовок запроса `x-api-key`).

## README из пакета

### 0.1.3 (дословно)

> Агент звукозаписи для МОС (Операционная система «Московской электронной школы»).
>
> Работает в фоне и записывает звук с входящих устройств по расписанию. Получает
> список сетевых устройств и их MAC адреса.
>
> Написан на Go

### 1.1.0 (дословно, фрагменты)

> Системный агент для МОС ... Агент обеспечивает проведение урока, работает как
> systemd-сервис от пользователя `mesh-agent` и получает задания от listener-server.
>
> Production endpoint синхронизации:
> `https://school.mos.ru/api/speech-analytics/internal/v1/agent/sync`
>
> ... Агент рассчитан на МОС и требует `arecord` и `ffmpeg`.

## Поведение (по символам бинарников)

Бинарники Go 1.25.11 (0.1.3) и 1.26.5 (1.1.0), stripped, но таблицы символов
сохранили имена функций `main.*`. Ключевые:

**Запись звука:** `recordJob`, `recordWAV`, `recordWAVWithARecord`,
`recordWAVCandidate`, `convertWavToOpus`, `collectAudioDevices`,
`findOktavaARecordDevice` (микрофоны «Октава»), `hasOktava`,
`inspectHDADevice`, `classifyRecordingDevice`, `selectTargetMicrophone`,
`wavSignalLevel`, `isUsableWAV`. Запись через `arecord`, кодирование OPUS через `ffmpeg`
(русские строки: «Файл успешно сконвертирован через ffmpeg!», «Ошибка вызова ffmpeg: %v»).

**Управление микрофоном (только 1.1.0):** `temporaryUnmute`, `readMuteState`,
`readMuteState`, `singleCaptureSwitch`, `setSwitchValuesContext`,
`probeWithTemporaryUnmute` — агент умеет временно снимать mute с микрофона на время
записи (через `amixer`/ALSA-переключатели HDA-кодека), то есть запись идёт, даже если
микрофон заглушён в системе.

**Сеть:** `newAPIClient`, `applyAuthHeaders` (заголовок `x-api-key`), `statusRequest`,
`probeSmbShare`, `writeSmbFile`, `writeSmbFileWithTimeout`, `smbDialer`
(библиотека `hirochachacha/go-smb2` — SMB2-клиент на Go). Статусы заданий:
`SCHEDULED`, `RECORDING`, `UPLOADING`, `JOB_EVENT`, `UPLOAD_FAILURE`.

**Учёт и локализация:** `readUDSAgentID` — идентификатор агента, `collectDeviceInfo`,
`collectNetworkInterfaces` (в т.ч. `GatewayMAC` — MAC-адрес шлюза), `collectOSInfo`,
`sha256File` (контрольные суммы записей), `metadataString`.

**Жизненный цикл записей:** `cleanup: job=%s deleted`, `keep-success-hours: 24`,
«recording files found on startup; local recording was discarded» — записи удаляются
после успешной отправки (хранятся ≤ 24 ч); при старте остатки локальных записей
уничтожаются.

**Уведомления (0.1.3):** `notifyRecordingStart`, `sendDesktopNotification`,
`runNotificationCommand`, скрипт `kde-notify` — уведомление пользователя на рабочий
стол KDE (notify-send через D-Bus plasmashell) о начале записи. В 1.1.0 скрипт
удалён из пакета.

**Удалённое управление:** задания приходят с сервера (`listener-server`); строка
1.1.0 «recording cancelled because job was removed by server» — сервер может
досрочно остановить запись. Периодичность опроса задана конфигом (30 с в 0.1.3).

## Осмотр одной доски (очная проверка)

В каталоге `/var/lib/cloudcom/agent/jobs` (заданный в конфигурации как `recording.root-dir`)
обнаружены каталоги заданий; почти все пустые, самый старый создан 16.10.2026. В одном
каталоге находился файл аудиозаписи. Согласуется с поведением удаления после отправки
(`keep-success-hours: 24`, `cleanup: job=%s deleted`): пустые каталоги — задания, записи
из которых ушли на сервер и были удалены. Предположительно запись велась начиная с
16.10.2026 (нижняя граница локальных следов на этой машине; не исключает более ранней
работы — каталоги могли очищаться при обновлениях).

## Особая сборка МОС для школ

Публичный репозиторий дистрибутивов МОС (`https://hub.mos.ru/mos/iso`, README.md)
содержит три образа, причём различие телеметрии заявлено самим разработчиком:

- «Для всех пользователей (без телеметрии без техподдержки ДИТ)» — пакет 33;
- «Для московских школ (с встроенной телеметрией и системой техподдержки ДИТ)»:
  - «Для компьютеров и ноутбуков» — пакет 37;
  - «Для интерактивных панелей» — пакет 38.

То есть встроенная телеметрия — заявленное свойство школьного образа МОС, а не
побочный эффект сторонних пакетов. `uds-system-agent` — часть этой телеметрии.

Фото интерактивной панели МосТех в классе: `docs/evidence/images/mostech-panel.jpg`
(источник: wiki it-help-school.ru, лицензия CC0).
SHA-256: `d08323b83a81bfae72ba0a092ac2586c264854268c19e1e83560297c96741c99`.

## Привязка панелей к адресам (регистрация в МОС)

Штатное приложение регистрации интерактивной панели в МОС (скриншоты на чистой
установке МОС 12 в виртуальной машине) требует при вводе в эксплуатацию указать:
ЕКИС организации, номер/наименование образовательной организации, номер/название/адрес
корпуса; имя компьютера формируется из номеров школы, корпуса, кабинета и id устройства
(«Введите номера или короткие названия английскими буквами школы, корпуса, кабинета и
устройства, согласно правилам именования»). В сочетании с работой агента именно на этих
панелях и его самоидентификацией серверу (readUDSAgentID, device info, GatewayMAC) это
означает: каждой доске соответствует запись в общей инвентаризационной базе с точным
адресом вплоть до кабинета.

Скриншоты: `docs/evidence/images/panel-registration-{1,2}.png`.
SHA-256: `5c2dfdd447e2120a29c0bd8514b460f3ea1a20bee668ccf03ef559ace69fec47`,
`7d04aa03c17a36920abc881e2ad617b519e20aa65089e0f6208a3555875eadc2`.

## Что подтверждено содержимым пакета

- ✅ запуск демоном (systemd, автозапуск);
- ✅ опрос сервера получения заданий (каждые 30 с в 0.1.3; 600 с в 1.1.0);
- ✅ звукозапись из аудитории (arecord, OPUS, mono 44.1 кГц);
- ✅ отправка записей на SMB-шару `MEDIASTG` и/или HTTP-эндпоинт загрузки;
- ✅ сервер `MEDIASTG` — локальный сервер в здании школы, подконтрольный ДИТ;
- ✅ удаление записей после отправки и при старте;
- ✅ сбор сведений об устройстве, сетевых интерфейсах и MAC-адресе шлюза;
- ✅ сборка в официальной инфраструктуре (Gitea ДИТ `hub.mos.ru`, ABF);
- ✅ подпись 0.1.3 ключом сборочной системы `abf@os.mos.ru`;
- ✅ подпись удалена в 1.1.0 (`Signature: (none)`, `rpm -K` → только `digests ОК`);
- ✅ описание 1.1.0 изменено с «Агент для аудиозаписи урока» на «Агент обеспечивает проведение урока»;
- ✅ распространение мимо публичного репозитория (локальный rpm, сервер ДИТ);
- ✅ production API-ключ `80f594fd-72d5-4a3a-8945-89a475d941df` (1.1.0).

## Что НЕ подтверждено (предположения)

- ❓ куда именно попадают записи после школьного сервера `MEDIASTG` (централизация аудио
  с серверов школ на более высоком уровне? объёмы хранения?) — из пакета не следует;
- ❓ используется ли распознавание речи / речевая аналитика на принимающей стороне
  (URL содержит `speech-analytics`, но клиент это не выполняет);
- ❓ правовая основа обработки звукозаписей уроков и статус оператора персональных данных;
- ❓ масштаб развёртывания (по факту наличия в школе — не означает массовость;
  но пакеты подписаны/собраны для массового развёртывания).

## Как воспроизвести разбор

```bash
sha256sum *.rpm
rpm -qpi mesh-agent-lesson-log-<версия>.x86_64.rpm
rpm -K  mesh-agent-lesson-log-<версия>.x86_64.rpm
rpm -qpl mesh-agent-lesson-log-<версия>.x86_64.rpm
mkdir ex && cd ex && rpm2cpio ../mesh-agent-lesson-log-<версия>.x86_64.rpm | cpio -idmv
cat etc/mesh-agent/config.json
cat usr/share/doc/mesh-agent-lesson-log/README.md
cat usr/lib/systemd/system/mesh-agent-lesson-log.service
strings -n 6 usr/bin/mesh-agent-lesson-log | grep -E 'main\.[a-z]'   # символы
strings -a usr/bin/mesh-agent-lesson-log | grep -oE 'go1\.[0-9.]+'  # версия Go
```

whois IP-адреса из конфигурации: `whois 82.148.29.56`.
