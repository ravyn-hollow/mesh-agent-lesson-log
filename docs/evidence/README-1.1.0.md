# mesh-agent

Системный агент для МОС (Операционная система «Московской электронной школы»).
Агент обеспечивает проведение урока, работает как systemd-сервис от пользователя
`mesh-agent` и получает задания от listener-server.

## Конфигурация

Основной конфигурационный файл:

```text
/etc/mesh-agent/config.json
```

Production endpoint синхронизации:

```text
https://school.mos.ru/api/speech-analytics/internal/v1/agent/sync
```

В `backend.base-url` указывается базовый адрес без суффикса `/sync`:

```json
{
  "backend": {
    "base-url": "https://school.mos.ru/api/speech-analytics/internal/v1/agent",
    "sync-interval-seconds": 600,
    "timeout-seconds": 30
  }
}
```

Production API key `80f594fd-72d5-4a3a-8945-89a475d941df` встроен в бинарный
файл. При необходимости его можно переопределить через `backend.api-key`:

```json
{
  "backend": {
    "api-key": "another-api-key"
  }
}
```

После изменения конфигурации:

```bash
sudo systemctl restart mesh-agent-lesson-log.service
sudo systemctl status mesh-agent-lesson-log.service --no-pager
```

DEBUG-логи включаются значением `DEBUG`:

```json
{
  "logging": {
    "level": "DEBUG"
  }
}
```

Просмотр логов:

```bash
sudo journalctl -u mesh-agent-lesson-log.service -f
```

## Локальная проверка

Агент рассчитан на МОС (Операционная система «Московской электронной школы») и
требует `arecord` и `ffmpeg`:

```bash
go run .
```

При локальном запуске также используется `/etc/mesh-agent/config.json`.
