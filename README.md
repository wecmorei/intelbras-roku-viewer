# Solução para Visualização de Câmeras Intelbras DVR no Roku

Este documento detalha a arquitetura, o desenvolvimento e as instruções de instalação para um aplicativo Roku que permite a visualização de câmeras de um DVR Intelbras. Devido à incompatibilidade direta do protocolo RTSP (utilizado pelos DVRs) com a plataforma Roku, uma solução intermediária de transcodificação é necessária.

## 1. Arquitetura da Solução

A solução proposta envolve três componentes principais:

1.  **DVR Intelbras**: Fonte dos streams de vídeo via protocolo RTSP.
2.  **Servidor Intermediário (Computador 24h)**: Um computador na mesma rede local do DVR que transcodifica os streams RTSP para HLS (HTTP Live Streaming), um formato compatível com o Roku. Este servidor também hospeda os arquivos HLS gerados.
3.  **Aplicativo Roku**: Um aplicativo desenvolvido em BrightScript/SceneGraph que consome os streams HLS do servidor intermediário e os exibe na TV.

```mermaid
graph TD
    A[DVR Intelbras] -->|RTSP| B(Servidor Intermediário)
    B -->|Transcodifica RTSP para HLS| C{Servidor Web (HLS)}
    C -->|HTTP (HLS)| D[Aplicativo Roku]
    D -->|Exibe na TV| E[Usuário]
```

## 2. Configuração do Servidor Intermediário

O servidor intermediário será responsável por converter o stream RTSP do DVR para HLS. Recomendamos o uso do FFmpeg para esta tarefa.

### 2.1. Instalação do FFmpeg

Certifique-se de que o FFmpeg esteja instalado no seu computador. Você pode baixá-lo do site oficial [1] ou instalá-lo via gerenciador de pacotes:

*   **Linux (Ubuntu/Debian)**:
    ```bash
    sudo apt update
    sudo apt install ffmpeg
    ```
*   **Windows**: Baixe o executável e adicione-o ao PATH do sistema.
*   **macOS**: Com Homebrew:
    ```bash
    brew install ffmpeg
    ```

### 2.2. Configuração do Servidor Web

Um servidor web é necessário para hospedar os arquivos HLS (`.m3u8` e `.ts`) gerados pelo FFmpeg. Você pode usar o Nginx, Apache ou um servidor Python simples.

**Exemplo com Python (para testes rápidos)**:

```bash
cd /caminho/para/servidor/web
python3 -m http.server 8080
```

Este comando iniciará um servidor HTTP na porta `8080` servindo os arquivos do diretório atual.

### 2.3. Comando FFmpeg para Transcodificação

Para cada câmera que você deseja visualizar, você precisará executar um comando FFmpeg. O comando abaixo converte um stream RTSP para HLS, gerando um arquivo `.m3u8` e segmentos `.ts`.

**Formato da URL RTSP Intelbras**:

`rtsp://usuario:senha@IP_DO_DVR:554/cam/realmonitor?channel=X&subtype=Y`

*   `usuario`: Nome de usuário do DVR (geralmente `admin`).
*   `senha`: Senha do DVR.
*   `IP_DO_DVR`: Endereço IP local do seu DVR Intelbras.
*   `554`: Porta padrão do RTSP (pode variar).
*   `channel=X`: Número do canal da câmera (ex: `1`, `2`, etc.).
*   `subtype=Y`: Tipo de stream (`0` para stream principal de alta qualidade, `1` para stream extra de menor qualidade).

**Exemplo de comando FFmpeg (para Câmera 1, stream principal)**:

```bash
ffmpeg -rtsp_transport tcp -i "rtsp://admin:suasenha@192.168.1.10:554/cam/realmonitor?channel=1&subtype=0" \
-c:v copy -c:a aac -ar 44100 -ac 1 -f hls -hls_time 2 -hls_list_size 3 -hls_flags delete_segments \
/caminho/para/servidor/web/camera1.m3u8
```

**Explicação dos parâmetros**: 
*   `-rtsp_transport tcp`: Força o uso de TCP para o RTSP, mais estável.
*   `-i "..."`: URL de entrada do stream RTSP.
*   `-c:v copy`: Copia o codec de vídeo original sem re-codificar (mais eficiente).
*   `-c:a aac -ar 44100 -ac 1`: Re-codifica o áudio para AAC (se houver áudio e for necessário para HLS).
*   `-f hls`: Define o formato de saída como HLS.
*   `-hls_time 2`: Define a duração de cada segmento HLS em 2 segundos.
*   `-hls_list_size 3`: Mantém apenas os 3 últimos segmentos na playlist HLS.
*   `-hls_flags delete_segments`: Deleta segmentos antigos para evitar acúmulo de arquivos.
*   `/caminho/para/servidor/web/camera1.m3u8`: Caminho completo para o arquivo de playlist HLS que será gerado. Este diretório deve ser o mesmo que o servidor web está servindo.

**Importante**: Execute um comando FFmpeg separado para cada câmera que você deseja visualizar. Certifique-se de que o `IP_DO_DVR` e as credenciais estejam corretos.

## 3. Aplicativo Roku

O aplicativo Roku é composto por um arquivo `manifest`, um arquivo `main.brs` (ponto de entrada) e componentes SceneGraph (`.xml` e `.brs`).

### 3.1. Estrutura de Diretórios

Crie a seguinte estrutura de diretórios no seu computador:

```
roku_intelbras_app/
├── manifest
├── source/
│   └── main.brs
├── components/
│   ├── MainScene.xml
│   └── MainScene.brs
└── images/
    ├── icon_hd.png
    ├── icon_sd.png
    ├── splash_hd.png
    └── splash_sd.png
```

### 3.2. Arquivos do Aplicativo

**`roku_intelbras_app/manifest`**:
```
title=Intelbras TV Viewer
major_version=1
minor_version=0
build_version=00001
mm_icon_focus_hd=pkg:/images/icon_hd.png
mm_icon_focus_sd=pkg:/images/icon_sd.png
splash_screen_hd=pkg:/images/splash_hd.png
splash_screen_sd=pkg:/images/splash_sd.png
ui_resolutions=fhd
```

**`roku_intelbras_app/source/main.brs`**:
```brightscript
sub Main()
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)

    scene = screen.CreateScene("MainScene")
    screen.Show()

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    end while
end sub
```

**`roku_intelbras_app/components/MainScene.xml`**:
```xml
<?xml version="1.0" encoding="utf-8" ?>
<component name="MainScene" extends="Scene">
    <script type="text/brightscript" uri="pkg:/components/MainScene.brs" />
    <children>
        <Video id="cameraPlayer" width="1920" height="1080" />
        <Label id="statusLabel" text="Conectando ao DVR Intelbras..." width="1920" height="100" translation="[0, 900]" horizAlign="center" />
    </children>
</component>
```

**`roku_intelbras_app/components/MainScene.brs`**:
```brightscript
sub init()
    m.video = m.top.findNode("cameraPlayer")
    m.status = m.top.findNode("statusLabel")
    
    ' Configurar o stream HLS (vindo do seu computador intermediário)
    ' Substitua o IP abaixo pelo IP do seu computador na rede local
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.url = "http://192.168.1.100:8080/camera1.m3u8" ' <--- ALTERE ESTE IP E PORTA
    videoContent.streamformat = "hls"
    videoContent.title = "Câmera Intelbras 1"
    
    m.video.content = videoContent
    m.video.control = "play"
    
    m.video.observeField("state", "onStateChange")
    m.top.setFocus(true)
end sub

sub onStateChange()
    state = m.video.state
    if state = "playing"
        m.status.visible = false
    else if state = "error"
        m.status.text = "Erro ao conectar: Verifique o servidor no computador."
        m.status.visible = true
    else if state = "buffering"
        m.status.text = "Carregando imagem..."
        m.status.visible = true
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press
        if key = "back"
            if m.video.state = "playing"
                m.video.control = "stop"
                return true
            end if
        end if
    end if
    return false
end function
```

**Observações sobre o código do Roku:**

*   Substitua `192.168.1.100:8080` pelo endereço IP e porta do seu servidor intermediário.
*   Para múltiplas câmeras, você precisaria de uma interface para selecionar qual câmera visualizar. Isso envolveria mais desenvolvimento na interface do usuário do Roku (por exemplo, uma lista de câmeras).
*   Os arquivos de imagem (`icon_hd.png`, `splash_hd.png`, etc.) devem ser adicionados ao diretório `images/` para que o aplicativo seja válido. Você pode usar imagens genéricas ou criar as suas próprias.

## 4. Instalação do Aplicativo no Roku

Para instalar o aplicativo no seu dispositivo Roku, você precisará habilitar o modo de desenvolvedor e fazer o *sideload* do pacote.

### 4.1. Habilitar Modo Desenvolvedor no Roku

1.  No seu dispositivo Roku, vá para **Configurações > Sistema > Sobre**.
2.  Pressione o seguinte sequência no controle remoto: **Home 3x, Up 2x, Right, Left, Right, Left, Right**.
3.  Isso abrirá o **Menu de Desenvolvedor**. Anote o endereço IP do seu Roku e a senha (se for solicitada uma).
4.  Selecione **Habilitar instalador de pacotes** e **Habilitar depurador**.

### 4.2. Empacotar e Instalar o Aplicativo

1.  Compacte o diretório `roku_intelbras_app` em um arquivo `.zip`. Certifique-se de que o `manifest` e os diretórios `source`, `components`, `images` estejam na raiz do `.zip`.
    ```bash
    cd /home/ubuntu/roku_intelbras_app
    zip -r ../roku_intelbras_app.zip .
    ```
2.  Abra um navegador web no seu computador e navegue até o endereço IP do seu Roku (anotado no passo 4.1).
3.  Você será solicitado a inserir o nome de usuário (`rokudev`) e a senha (se você configurou uma).
4.  Na interface web do desenvolvedor, clique em **Upload** ou **Install**.
5.  Selecione o arquivo `roku_intelbras_app.zip` que você criou e clique em **Install**.
6.  O aplicativo será instalado e aparecerá na tela inicial do seu Roku.

## 5. Acesso Externo com Cloudflare Tunnel

Para acessar suas câmeras fora da rede local (pela internet) de forma segura, utilizaremos o **Cloudflare Tunnel**. Esta solução cria um túnel seguro entre o seu computador (servidor intermediário) e a internet, eliminando a necessidade de abrir portas no seu roteador, o que aumenta a segurança.

### 5.1. Requisitos

*   Uma conta gratuita na [Cloudflare](https://dash.cloudflare.com/sign-up).
*   Um domínio próprio (pode ser um domínio gratuito ou comprado, ex: `minhascameras.com`).

### 5.2. Instalação do Cloudflared (No Computador 24h)

O `cloudflared` é o programa que cria e mantém o túnel. Instale-o no seu computador que atua como servidor intermediário:

*   **Windows**: Baixe o instalador `.msi` no [site oficial do Cloudflare Tunnel](https://github.com/cloudflare/cloudflared/releases).
*   **Linux (Ubuntu/Debian)**:
    ```bash
    curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
    sudo dpkg -i cloudflared.deb
    ```
*   **macOS**: Com Homebrew:
    ```bash
    brew install cloudflare/cloudflared/cloudflared
    ```

### 5.3. Configuração do Túnel

Execute os comandos abaixo no terminal do seu computador:

1.  **Login na Cloudflare**:
    ```bash
    cloudflared tunnel login
    ```
    Este comando abrirá uma página no seu navegador para autenticação na sua conta Cloudflare. Após o login, selecione o domínio que você deseja usar para o túnel.

2.  **Criar o Túnel**:
    ```bash
    cloudflared tunnel create intelbras-tunnel
    ```
    Anote o **ID do túnel** que será gerado (ex: `a7f3e8c2-1b4d-4e5f-8a9b-0c1d2e3f4a5b`). Você precisará dele para os próximos passos.

3.  **Configurar o Nome de Acesso (Hostname)**:
    Este comando associa um subdomínio ao seu túnel, tornando-o acessível publicamente. Substitua `ID_DO_TUNEL` pelo ID gerado no passo anterior e `cameras.seudominio.com` pelo endereço que você deseja usar (ex: `cameras.meudominio.com`):
    ```bash
    cloudflared tunnel route dns intelbras-tunnel cameras.seudominio.com
    ```

4.  **Criar Arquivo de Configuração (`config.yml`)**:
    Crie um arquivo chamado `config.yml` na pasta de configuração do `cloudflared` (geralmente `~/.cloudflared/` no Linux/macOS ou `C:\Users\SeuUsuario\.cloudflared\` no Windows) com o seguinte conteúdo:

    ```yaml
    tunnel: ID_DO_TUNEL
    credentials-file: /caminho/para/o/arquivo/de/credenciais.json

    ingress:
      - hostname: cameras.seudominio.com
        service: http://localhost:8080
      - service: http_status:404
    ```
    *   Substitua `ID_DO_TUNEL` pelo ID do seu túnel.
    *   O `credentials-file` é gerado automaticamente após o `cloudflared tunnel login` e o `cloudflared tunnel create`. Verifique o caminho correto no seu sistema.
    *   O `service: http://localhost:8080` deve apontar para o endereço e porta onde o seu servidor web local (que serve os streams HLS do FFmpeg) está rodando.

5.  **Rodar o Túnel como Serviço**:
    Para que o túnel inicie automaticamente com o sistema operacional e funcione em segundo plano:
    *   **Windows**: Abra o Prompt de Comando (Admin) e execute `cloudflared service install`.
    *   **Linux**: Execute `sudo cloudflared service install`.
    *   **macOS**: `sudo brew services start cloudflared`

### 5.4. Atualização no Aplicativo Roku

Com o Cloudflare Tunnel configurado, você terá um endereço público (ex: `https://cameras.seudominio.com`) que aponta para o seu servidor HLS local. Você deve atualizar a URL no código do seu aplicativo Roku para usar este novo endereço, permitindo o acesso de qualquer lugar.

No arquivo `components/MainScene.brs`, altere a linha da URL:

```brightscript
' Antes (Local):
' videoContent.url = "http://192.168.1.100:8080/camera1.m3u8"

' Depois (Externo):
videoContent.url = "https://cameras.seudominio.com/camera1.m3u8" ' <--- ALTERE ESTE ENDEREÇO
```

### 5.5. Dicas de Segurança (Importante)

Expor seus streams de vídeo à internet requer atenção redobrada à segurança:

1.  **Cloudflare Access**: Para proteger o acesso, configure o Cloudflare Access no painel Zero Trust da Cloudflare. Isso permite adicionar autenticação (por e-mail, Google, etc.) antes que o usuário possa acessar o stream.
2.  **HTTPS**: O Cloudflare Tunnel já fornece HTTPS por padrão, garantindo que a comunicação entre o Roku e o seu servidor seja criptografada.
3.  **Restrição de IP**: Se você sempre acessará de um conjunto fixo de IPs, pode configurar regras de firewall na Cloudflare para permitir acesso apenas a esses IPs.

## Referências

[1] FFmpeg. *FFmpeg Download*. Disponível em: [https://ffmpeg.org/download.html](https://ffmpeg.org/download.html)
[2] Cloudflare. *Cloudflare Tunnel*. Disponível em: [https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/)

---

**Autor**: Manus AI
**Data**: 20 de Abril de 2026
