# sg_vpp

**sg_vpp** je veřejný skript vytvořený pro platformu FiveM, který je napsán v jazyce Lua. Projekt je rozdělen do tří hlavních složek: `client`, `server` a `shared`, což naznačuje modulární strukturu typickou pro vývoj skriptů ve FiveM.

## 📁 Struktura projektu

- **client/**: Obsahuje klientské skripty, které běží na straně hráče.
- **server/**: Obsahuje serverové skripty, které běží na straně serveru.
- **shared/**: Obsahuje sdílené skripty a konfigurace, které jsou společné pro klienta i server.
- **fxmanifest.lua**: Definuje metadata a závislosti pro FiveM.
- **LICENSE**: Projekt je licencován pod licencí Apache 2.0.
- **README.md**: Tento soubor s informacemi o projektu.

## ⚙️ Instalace

1. Naklonuj repozitář do složky `resources` ve tvém FiveM serveru:
   ```bash
   git clone https://github.com/Merodicoexe/sg_vpp.git
