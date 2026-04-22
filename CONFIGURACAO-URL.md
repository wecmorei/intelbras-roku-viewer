# 📱 Configuração de URL - Intelbras Roku Viewer

## Opção 1: Acesso Local (Mesmo WiFi)

### Para Vilas de Quitaúna em Docker

Edite `components/MainScene.brs` e substitua a linha:

```brightscript
videoContent.url = "http://192.168.1.100:8000/hls/camera.m3u8"
```

**Substitua:**
- `192.168.1.100` pelo IP da máquina onde Docker está rodando

---

## Opção 2: Acesso Externo (Cloudflare Tunnel)

Edite `components/MainScene.brs` e substitua a linha:

```brightscript
videoContent.url = "https://cameras.seudominio.com/hls/camera.m3u8"
```

**Substitua:**
- `cameras.seudominio.com` pelo seu domínio Cloudflare

---

## Encontrando o IP da Máquina Local

### Windows (PowerShell)
```powershell
ipconfig
# Procure por "IPv4 Address" na seção da sua rede (ex: 192.168.x.x)
```

### Linux/Mac (Terminal)
```bash
ifconfig
# ou
hostname -I
# Procure por um IP tipo 192.168.x.x ou 10.0.x.x
```

---

## Template Configurável

Se preferir, você pode editar o arquivo abaixo antes de empacotar:

### 1. Duplicar MainScene.brs para manter original
```bash
cp components/MainScene.brs components/MainScene.brs.backup
```

### 2. Editar conforme sua necessidade
```bash
# Windows (PowerShell)
notepad components/MainScene.brs

# Linux/Mac
nano components/MainScene.brs
```

### 3. Procurar a linha com `.url =` e alterar
A linha está em torno da linha **9**.

**Antes:**
```brightscript
videoContent.url = "http://192.168.1.100:8080/camera1.m3u8"
```

**Depois (Local):**
```brightscript
videoContent.url = "http://192.168.1.50:8000/hls/camera.m3u8"
```

**Ou Depois (Externo):**
```brightscript
videoContent.url = "https://cameras.seudominio.com/hls/camera.m3u8"
```

---

## Testar URL no Navegador

Antes de empacotar, teste a URL no navegador do PC:

- **Local**: http://192.168.1.50:8000/hls/camera.m3u8
- **Externo**: https://cameras.seudominio.com/hls/camera.m3u8

Se abrir um arquivo `.m3u8` ou se o VLC tentar abrir, está OK! ✅

---

## URLs do Vilas de Quitaúna

| Recurso | URL Local | URL Externa |
|---------|-----------|------------|
| Dashboard | http://192.168.x.x:8000 | https://cameras.seudominio.com |
| API Docs | http://192.168.x.x:8000/docs | https://cameras.seudominio.com/docs |
| Stream HLS | http://192.168.x.x:8000/hls/camera.m3u8 | https://cameras.seudominio.com/hls/camera.m3u8 |

---

## 🚀 Próximas Etapas

1. ✅ Editar URL em `components/MainScene.brs`
2. ✅ Empacotar app em ZIP
3. ✅ Instalar no Roku (ver GUIA-FINAL-INTEGRADO.md)

---

**Dúvidas?** Ver `../vilas_quitauna/GUIA-FINAL-INTEGRADO.md`
