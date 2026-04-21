sub init()
    m.video = m.top.findNode("cameraPlayer")
    m.status = m.top.findNode("statusLabel")
    
    ' Configurar o stream HLS (vindo do seu computador intermediário)
    ' Substitua o IP abaixo pelo IP do seu computador na rede local
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.url = "http://192.168.1.100:8080/camera1.m3u8"
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
