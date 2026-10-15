@echo off
chcp 65001 >nul
setlocal EnableExtensions
title Apagador 1.0.0 - Actualizar
color 0F

powershell -NoProfile -ExecutionPolicy Bypass -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; $l=[IO.File]::ReadAllLines('%~f0',[Text.Encoding]::UTF8); $a=[Array]::IndexOf($l,':::BANNERSTART'); $b=[Array]::IndexOf($l,':::BANNEREND'); foreach($t in $l[($a+1)..($b-1)]){ $p=$t.Split([char]0xA7); Write-Host -NoNewline $p[0] -ForegroundColor DarkCyan; if($p.Length -gt 1){ Write-Host -NoNewline 'O' -ForegroundColor DarkYellow; Write-Host $p[1] -ForegroundColor DarkCyan } else { Write-Host '' } }; $a=[Array]::IndexOf($l,':::TITULOSTART'); $b=[Array]::IndexOf($l,':::TITULOEND'); $l[($a+1)..($b-1)] | ForEach-Object { Write-Host $_ -ForegroundColor White }"
echo.
echo Esto sustituye el programa por la version nueva, EN ESTA MISMA CARPETA.
echo No toca tus datos.
echo.
echo Cierra antes Apagador si lo tienes abierto.
echo.
pause

set "SELF=%~f0"
set "SELF_DIR=%~dp0"
if "%SELF_DIR:~-1%"=="\" set "SELF_DIR=%SELF_DIR:~0,-1%"
for %%I in ("%SELF_DIR%") do set "SELF_NAME=%%~nxI"
set "INSTALL_DIR=%SELF_DIR%"
if /i "%SELF_NAME%"=="instaladores" for %%I in ("%SELF_DIR%\..") do set "INSTALL_DIR=%%~fI"
set "WORKDIR=%TEMP%\apagador_actualizar_%RANDOM%"

if exist "%INSTALL_DIR%\apagador_app.py" goto :hay_instalacion
echo.
echo No encuentro una instalacion de Apagador en esta carpeta:
echo   %INSTALL_DIR%
echo Esto actualiza una instalacion que ya exista aqui. Si es la primera
echo vez, usa el instalador completo ^(el que tambien mete Python^).
pause
exit /b 1

:hay_instalacion
if not exist "%WORKDIR%" mkdir "%WORKDIR%" >nul 2>&1

echo.
echo [1/4] Guardando una copia de lo anterior, por si acaso...
set "COPIAS=%INSTALL_DIR%\anteriores"
if not exist "%COPIAS%" mkdir "%COPIAS%" >nul 2>&1
if exist "%INSTALL_DIR%\apagador_app.py" xcopy "%INSTALL_DIR%\apagador_app.py" "%COPIAS%\anterior\" /y /q >nul 2>&1

echo.
echo [2/4] Extrayendo la version nueva...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$l=Get-Content -LiteralPath '%SELF%' -Encoding UTF8; $s=($l | Select-String -SimpleMatch ':::PSSTART' | Select-Object -Last 1).LineNumber; $e=($l | Select-String -SimpleMatch ':::PSEND' | Select-Object -Last 1).LineNumber; $l[$s..($e-2)] | Set-Content -LiteralPath '%WORKDIR%\extraer.ps1' -Encoding UTF8"
if not exist "%WORKDIR%\extraer.ps1" (
    echo No se ha podido preparar la actualizacion ^(fallo al extraer el script^).
    pause
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%WORKDIR%\extraer.ps1" "%SELF%" "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\apagador_app.py" (
    echo No se ha podido extraer apagador_app.py.
    pause
    exit /b 1
)

echo.
echo [3/4] Buscando Python...

set "PYEXE="
if exist "%INSTALL_DIR%\python\python.exe" call :probar "%INSTALL_DIR%\python\python.exe"
if not defined PYEXE for /f "delims=" %%P in ('py -3 -c "import sys; print(sys.executable)" 2^>nul') do if not defined PYEXE call :probar "%%P"
if not defined PYEXE for /f "delims=" %%P in ('python -c "import sys; print(sys.executable)" 2^>nul') do if not defined PYEXE call :probar "%%P"

if defined PYEXE goto :con_python
echo       No encuentro un Python valido. El programa se ha actualizado, pero
echo       si falta algo usa el instalador completo.
goto :accesos

:con_python
echo       Python: %PYEXE%

set "PYWEXE=%PYEXE:python.exe=pythonw.exe%"

:accesos

echo.
echo [4/4] Actualizando los accesos directos ^(si existen^)...
if defined PYWEXE powershell -NoProfile -ExecutionPolicy Bypass -Command "$w=New-Object -ComObject WScript.Shell; foreach($c in @($w.SpecialFolders('Desktop'),$w.SpecialFolders('Startup'))){ $f=Join-Path $c 'Apagador.lnk'; if(Test-Path -LiteralPath $f){ $s=$w.CreateShortcut($f); if($s.TargetPath -like '*pythonw.exe'){ $s.TargetPath='%PYWEXE%'; $s.Arguments='\"%INSTALL_DIR%\apagador_app.py\"'; $s.WorkingDirectory='%INSTALL_DIR%'; $s.IconLocation='%INSTALL_DIR%\apagador.ico'; $s.Save() } } }"

echo.
echo Actualizacion terminada.
echo Abre Apagador desde el acceso directo del Escritorio.
echo Si algo fuera mal, el programa anterior quedo guardado en:
echo   %COPIAS%\anterior
echo.
pause

rmdir /s /q "%WORKDIR%" >nul 2>&1
exit /b 0

:probar
"%~1" -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>&1
if not errorlevel 1 set "PYEXE=%~1"
exit /b 0

:::PSSTART
param([string]$self, [string]$dest)
$enc = New-Object System.Text.UTF8Encoding($false)
$lines = [System.IO.File]::ReadAllLines($self, $enc)
$i = 0
while ($i -lt $lines.Length) {
    $l = $lines[$i]
    if ($l.StartsWith(':::BEGIN ')) {
        $partes = $l.Substring(9).Trim().Split('|')
        $rel = $partes[0]
        $modo = $partes[1]
        $j = $i + 1
        $buf = New-Object System.Collections.Generic.List[string]
        while ($j -lt $lines.Length -and -not $lines[$j].StartsWith(':::END')) {
            $buf.Add($lines[$j])
            $j++
        }
        $destino = Join-Path $dest $rel
        $carpeta = Split-Path -Parent $destino
        if (-not (Test-Path -LiteralPath $carpeta)) {
            New-Item -ItemType Directory -Path $carpeta -Force | Out-Null
        }
        if ($modo -eq 'b64') {
            [System.IO.File]::WriteAllBytes($destino, [Convert]::FromBase64String(($buf -join '')))
        } else {
            [System.IO.File]::WriteAllText($destino, (($buf -join "`r`n") + "`r`n"), $enc)
        }
        $i = $j
    }
    $i++
}
:::PSEND

:::BANNERSTART
░▒▓█ ══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ █▓▒░
                                                              *#@@@@@@%#
                                                           *%%%%@@@@%%@%+#########
                                                         *#####%%%%+§+---+#%%@@@@@@@%#
                                                       *#####%%%@@#-+*+#%@@@@@@@@@@@@@%#
                                                      ##*##%##%%%@%*#%#*#%%%%%@@%####*
                                                     %##**#%%%%%%%%%%%*=*###%
                                                   #####**#%%%@@%%%%**#%%%%%
                                               *%@@%%###***##%%@%%%%%%%%%%#
                                            #@@@@@@@@@%%%%##**%#%%%%%%@@%%
                                         #%@@@@@@@@@@@@@@@%%%*##%%%%%%%%%%
                                      *%@@@@@@@@@@@###%%%%%%%##%%%@@%%%%%%#
                                    #@@@@%@%%@%%#*##%%%@%@@@@@%#%%@%%%#%%%
                                  #@@@@%%%#*****#%%@@@@@@@@@@@@##%%%#%#*%%
                                 %%@@%##***##%@@@@%@@@@@@@@@@@%%##%%##*#%
                              +#%%@%###%%%%@@@@@%@@%@@@@@@@@@##%%%%%%%##
                            *##**##%@%%@@@@@@@@@@@@@@@@%@@%%##%%%%%#####
                          ##**+#%@@%%%@@%%@%@@@@@%@%%%%@@@#*%%@%%#%%#%*
                        %###%@@@@%#%%%%%%%#%%#%%#%#*#%%%%*#%%%%@%%%%%
                     *%%%%@@@@%#*#######*##*****+++*#%%+*%%%@%%%#%##
                   *@@@@@@@@###@%@%%%%%%%#####*=*#%#%*+#%%#%%%%%##*
                  %@@@@@@%##%%@@@@@%%%%%%%%%%%#***++=#%%%#%%%###%+                                  ██╗  ██╗ ██╗   ██╗ ███████╗ ██████╗  ██████╗   ██████╗
                %%@@@@%###%@@@@@%#%%@@@@%%%%%#+--=+*#%@%%%%#**%%*                             #     ██║ ██╔╝ ██║   ██║ ██╔════╝ ██╔══██╗ ██╔══██╗ ██╔═████╗
               %@@@%#**%%%@@@%%##%#%@@%%%%#*==+*%%%%%%%%#*****#                             %@      █████╔╝  ██║   ██║ █████╗   ██████╔╝ ██████╔╝ ██║██╔██║
                ###*##%%@%%%%%%%#*#%%%%#+=-=+*#%####%%#+***+**                            #@@*      ██╔═██╗  ██║   ██║ ██╔══╝   ██╔══██╗ ██╔══██╗ ████╔╝██║
                #%%@@@@@@%@%%%#++=*++=====+==*******%**+++*#                             %@@%       ██║  ██╗ ╚██████╔╝ ███████╗ ██║  ██║ ██████╔╝ ╚██████╔╝
              #%%@@@@@@%%%%%*++***=-==++=++=*+=++***==+**#                              %@@#        ╚═╝  ╚═╝  ╚═════╝  ╚══════╝ ╚═╝  ╚═╝ ╚═════╝   ╚═════╝
            *@%@@@%@%%%%#++=**++==+==-=---=-===+=##**##                               #@@%
           %@@@@%%###*++*#+#*+*#+=*= *--====--=**%*                                 *%@@@           Without data, you’re just another person with an opinion
         %@@@@%#***+=*#%#*+**++*+     ***##**++#*                                 #@@@@@@%#%@@@@%
       %@@@%%##* **#%%@*+*+**+          *%%*   *%%*                          *#%@@@@@@@@@@@@####
     %@@@%%%*   #%%%@%*++**+              %%#    #%%#                  ##%@@@@@@@@@@##
   #@@@@%*     %%@%%#++*#*                 #@%     *%@@##  ##**+#@@@@@@@@@@@@@@@#
  #@@@#       %@@%%#+#%%*                   %@@####%%%%%%%%%%@%%@@@@@@@@@@@@@@@@
 %@%*        %@@#%#*%%%*                #%%%%#%@%@%@@@%%%%%@@@@%@@@####        #@%
##          @@%#%#*%%%                 **%%@@@%%%#@#%%@@%%####+**                #@%#
           @@%%#*#%%%                *%@@@@@@@@%%%@@%##                            #%%
         #@@%%**#%@#               #@@@@@@@@@@@%%%%@                                 #
        #@%%#*#%#%              *@@@@@@@@@@%#
       %@%%##%%%              *%@@@@@@@@%*
      %@%%%%%%               %@@@@@@@@@#
      @# ##                #@@@@@@@@@#
                         #@@@@@@@@@%
                        %@@@@@@@@@#
                       @@@@@@@@@@#
                      @@@@@@@@@@#
                     @@@@@@@@@@#
                    @@@@@@@@@@%
                   %@@@@@@@@@%
░▒▓█ ══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ █▓▒░
:::BANNEREND
:::TITULOSTART

                          █████╗   ██████╗ ████████╗ ██╗   ██╗  █████╗  ██╗      ██╗ ███████╗  █████╗  ██████╗   ██████╗  ██████╗
                         ██╔══██╗ ██╔════╝ ╚══██╔══╝ ██║   ██║ ██╔══██╗ ██║      ██║ ╚══███╔╝ ██╔══██╗ ██╔══██╗ ██╔═══██╗ ██╔══██╗
                         ███████║ ██║         ██║    ██║   ██║ ███████║ ██║      ██║   ███╔╝  ███████║ ██║  ██║ ██║   ██║ ██████╔╝
                         ██╔══██║ ██║         ██║    ██║   ██║ ██╔══██║ ██║      ██║  ███╔╝   ██╔══██║ ██║  ██║ ██║   ██║ ██╔══██╗
                         ██║  ██║ ╚██████╗    ██║    ╚██████╔╝ ██║  ██║ ███████╗ ██║ ███████╗ ██║  ██║ ██████╔╝ ╚██████╔╝ ██║  ██║
                         ╚═╝  ╚═╝  ╚═════╝    ╚═╝     ╚═════╝  ╚═╝  ╚═╝ ╚══════╝ ╚═╝ ╚══════╝ ╚═╝  ╚═╝ ╚═════╝   ╚═════╝  ╚═╝  ╚═╝

                                          █████╗  ██████╗   █████╗   ██████╗   █████╗  ██████╗   ██████╗  ██████╗
                                         ██╔══██╗ ██╔══██╗ ██╔══██╗ ██╔════╝  ██╔══██╗ ██╔══██╗ ██╔═══██╗ ██╔══██╗
                                         ███████║ ██████╔╝ ███████║ ██║  ███╗ ███████║ ██║  ██║ ██║   ██║ ██████╔╝
                                         ██╔══██║ ██╔═══╝  ██╔══██║ ██║   ██║ ██╔══██║ ██║  ██║ ██║   ██║ ██╔══██╗
                                         ██║  ██║ ██║      ██║  ██║ ╚██████╔╝ ██║  ██║ ██████╔╝ ╚██████╔╝ ██║  ██║
                                         ╚═╝  ╚═╝ ╚═╝      ╚═╝  ╚═╝  ╚═════╝  ╚═╝  ╚═╝ ╚═════╝   ╚═════╝  ╚═╝  ╚═╝

                                                                    V E R S I Ó N   1.0.0
:::TITULOEND

:::BEGIN apagador_app.py|text
"""
Apagador programado con interfaz grafica.
Permite elegir una duracion en minutos o una hora exacta del dia
para programar el apagado de Windows. Se puede cancelar en cualquier
momento, incluso durante la cuenta atras.
"""
import tkinter as tk
from tkinter import ttk
import os
import sys
import datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ICON_PATH = os.path.join(BASE_DIR, "apagador.ico")


def main():
    root = tk.Tk()
    root.title("Apagador")
    root.geometry("900x650")
    root.attributes("-topmost", True)

    if os.path.exists(ICON_PATH):
        try:
            root.iconbitmap(ICON_PATH)
        except tk.TclError:
            pass

    bg_color = "#222222"
    fg_color = "#f0f0f0"
    accent_color = "#53B9F5"
    btn_color = "#333333"
    btn_fg = "#ffffff"
    root.configure(bg=bg_color)

    modo = tk.StringVar(value="duracion")  # "duracion" u "hora"
    valor_seleccionado = tk.IntVar(value=45)   # minutos (duracion)
    hora_seleccionada = tk.IntVar(value=23)    # hora exacta (0-23)
    minuto_seleccionado = tk.IntVar(value=0)   # minuto exacto (0-59)

    estado = {"programado": False}
    segundos_restantes = {"valor": 0}

    contenedor = tk.Frame(root, bg=bg_color)
    contenedor.pack(expand=True, fill="both")

    label = tk.Label(
        contenedor, text="Programar apagado",
        pady=10, bg=bg_color, fg=fg_color, font=("Arial", 18, "bold")
    )
    label.pack(pady=(30, 10))

    # --- Selector de modo ---
    modo_frame = tk.Frame(contenedor, bg=bg_color)
    modo_frame.pack(pady=10)

    style = ttk.Style()
    style.theme_use("default")
    style.configure(
        "Dark.TRadiobutton",
        background=bg_color, foreground=fg_color,
        font=("Arial", 13)
    )
    style.map("Dark.TRadiobutton", background=[("active", bg_color)])

    panel_duracion = tk.Frame(contenedor, bg=bg_color)
    panel_hora = tk.Frame(contenedor, bg=bg_color)

    def mostrar_panel():
        if modo.get() == "duracion":
            panel_hora.pack_forget()
            panel_duracion.pack(pady=10)
        else:
            panel_duracion.pack_forget()
            panel_hora.pack(pady=10)

    rb_duracion = ttk.Radiobutton(
        modo_frame, text="Duracion (minutos)", value="duracion",
        variable=modo, style="Dark.TRadiobutton", command=mostrar_panel
    )
    rb_hora = ttk.Radiobutton(
        modo_frame, text="Hora exacta", value="hora",
        variable=modo, style="Dark.TRadiobutton", command=mostrar_panel
    )
    rb_duracion.pack(side="left", padx=15)
    rb_hora.pack(side="left", padx=15)

    # --- Panel duracion (slider hasta 360 minutos = doble de 180) ---
    label_minutos = tk.Label(
        panel_duracion, text="Selecciona los minutos hasta el apagado:",
        bg=bg_color, fg=fg_color, font=("Arial", 14)
    )
    label_minutos.pack()

    slider = tk.Scale(
        panel_duracion, from_=0, to_=360,
        orient="horizontal", resolution=10,
        variable=valor_seleccionado,
        length=700, font=("Arial", 18),
        sliderlength=50, width=60,
        bg=accent_color, fg=fg_color,
        troughcolor=bg_color,
        highlightbackground=bg_color,
        highlightcolor=bg_color,
        activebackground=btn_color,
    )
    slider.pack(pady=10)

    # --- Panel hora exacta ---
    label_hora = tk.Label(
        panel_hora, text="Selecciona la hora de apagado:",
        bg=bg_color, fg=fg_color, font=("Arial", 14)
    )
    label_hora.pack(pady=(0, 10))

    selector_frame = tk.Frame(panel_hora, bg=bg_color)
    selector_frame.pack()

    spin_hora = tk.Spinbox(
        selector_frame, from_=0, to=23, width=4,
        format="%02.0f", font=("Arial", 24),
        textvariable=hora_seleccionada, wrap=True,
        justify="center", bg=btn_color, fg=fg_color,
        buttonbackground=btn_color, insertbackground=fg_color
    )
    spin_hora.pack(side="left", padx=5)

    tk.Label(
        selector_frame, text=":", bg=bg_color, fg=fg_color, font=("Arial", 24, "bold")
    ).pack(side="left")

    spin_minuto = tk.Spinbox(
        selector_frame, from_=0, to=59, width=4,
        format="%02.0f", font=("Arial", 24),
        textvariable=minuto_seleccionado, wrap=True,
        justify="center", bg=btn_color, fg=fg_color,
        buttonbackground=btn_color, insertbackground=fg_color
    )
    spin_minuto.pack(side="left", padx=5)

    mostrar_panel()

    estado_label = tk.Label(contenedor, text="", bg=bg_color, fg=accent_color, font=("Arial", 20, "bold"))
    estado_label.pack(pady=20)

    btn_frame = tk.Frame(contenedor, bg=bg_color)
    btn_frame.pack(pady=10)

    def calcular_segundos():
        if modo.get() == "duracion":
            minutos = valor_seleccionado.get()
            if minutos == 0:
                minutos = 1
            return minutos * 60
        else:
            ahora = datetime.datetime.now()
            objetivo = ahora.replace(
                hour=hora_seleccionada.get(),
                minute=minuto_seleccionado.get(),
                second=0, microsecond=0
            )
            if objetivo <= ahora:
                objetivo += datetime.timedelta(days=1)
            return int((objetivo - ahora).total_seconds())

    def actualizar_cuenta_atras():
        if not estado["programado"]:
            return
        h, resto = divmod(segundos_restantes["valor"], 3600)
        m, s = divmod(resto, 60)
        if h > 0:
            estado_label.config(text=f"Apagando en {h:02d}:{m:02d}:{s:02d}")
        else:
            estado_label.config(text=f"Apagando en {m:02d}:{s:02d}")
        if segundos_restantes["valor"] <= 0:
            os.system("shutdown /s /f /t 0")
            root.destroy()
            return
        segundos_restantes["valor"] -= 1
        root.after(1000, actualizar_cuenta_atras)

    def set_controles(activo):
        estado_ctrl = "normal" if activo else "disabled"
        slider.config(state=estado_ctrl)
        spin_hora.config(state=estado_ctrl)
        spin_minuto.config(state=estado_ctrl)
        rb_duracion.config(state=estado_ctrl)
        rb_hora.config(state=estado_ctrl)
        btn_confirmar.config(state=estado_ctrl)

    def al_confirmar():
        estado["programado"] = True
        segundos_restantes["valor"] = calcular_segundos()
        set_controles(False)
        actualizar_cuenta_atras()
        root.iconify()  # minimiza la ventana al confirmar

    def al_cancelar():
        os.system("shutdown /a")
        estado["programado"] = False
        estado_label.config(text="Apagado cancelado.")
        set_controles(True)

    btn_confirmar = tk.Button(
        btn_frame, text="Confirmar y Continuar", command=al_confirmar,
        bg=btn_color, fg=btn_fg, font=("Arial", 14), width=20
    )
    btn_confirmar.pack(side="left", padx=10)

    btn_cancelar = tk.Button(
        btn_frame, text="Cancelar Apagado", command=al_cancelar,
        bg=btn_color, fg=btn_fg, font=("Arial", 14), width=15
    )
    btn_cancelar.pack(side="left", padx=10)

    root.mainloop()


if __name__ == "__main__":
    main()
:::END
:::BEGIN apagador.ico|b64
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
:::END
:::BEGIN VERSION.txt|text
1.0.0
:::END
:::BEGIN herramientas/descargar_python.ps1|text
# Descarga el instalador de Python para Windows (64 bits) a la ruta indicada.
# Busca en python.org la version 3.13 mas reciente que tenga instalador y,
# si no puede, prueba con una lista de versiones conocidas.
param([string]$Destino)

$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$base = 'https://www.python.org/ftp/python/'

$candidatas = @()
try {
    $html = (Invoke-WebRequest -UseBasicParsing -Uri $base -TimeoutSec 30).Content
    $candidatas = @([regex]::Matches($html, '3\.13\.\d+(?=/)') |
        ForEach-Object { $_.Value } |
        Sort-Object { [version]$_ } -Descending -Unique)
} catch { }

$respaldo = @('3.13.9', '3.13.7', '3.13.5', '3.13.3', '3.12.10')
$versiones = @($candidatas) + @($respaldo) | Select-Object -Unique

foreach ($v in $versiones) {
    $url = "$base$v/python-$v-amd64.exe"
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Destino -TimeoutSec 600
        if ((Test-Path -LiteralPath $Destino) -and ((Get-Item -LiteralPath $Destino).Length -gt 1MB)) {
            Write-Host "      Descargado Python $v"
            exit 0
        }
    } catch { }
    if (Test-Path -LiteralPath $Destino) { Remove-Item -LiteralPath $Destino -Force }
}
exit 1
:::END
