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
