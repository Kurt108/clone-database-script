# nix-bash-script

## Übersicht

Dieses Projekt enthält ein Bash-Skript, das verwendet wird, um eine Datenbank von einem MariaDB-Cluster zu klonen. Es führt verschiedene Schritte aus, um eine Verbindung zum Cluster herzustellen, die Datenbank zu dumpen und die Dump-Datei zu speichern.

## Dateien

- `src/clone-database-script.sh`: Das Bash-Skript, das die Datenbank klont.
- `default.nix`: Definiert das Nix-Paket für das Bash-Skript.
- `shell.nix`: Definiert die Nix-Umgebung für die Entwicklung.

## Installation

Um das Nix-Paket zu installieren, stellen Sie sicher, dass Nix auf Ihrem System installiert ist. Führen Sie dann den folgenden Befehl aus:

```bash
nix-build
```

## Verwendung

Um das Skript auszuführen, verwenden Sie den folgenden Befehl:

```bash
./result/bin/clone-database-script
```

Stellen Sie sicher, dass Sie die erforderlichen Berechtigungen haben und dass die MariaDB-Umgebung korrekt konfiguriert ist.

## Beitrag

Beiträge sind willkommen! Bitte öffnen Sie ein Issue oder einen Pull-Request, um Änderungen vorzuschlagen.