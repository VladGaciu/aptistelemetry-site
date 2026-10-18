import kivy
kivy.require('2.1.0')

from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.clock import Clock
import requests
import threading

class AptisRootLayout(BoxLayout):
    def __init__(self, **kwargs):
        super(AptisRootLayout, self).__init__(**kwargs)
        self.orientation = 'vertical'
        self.padding = 20
        self.spacing = 15

        # Title Header
        self.title_label = Label(
            text='APTIS // MOBILE TELEMETRY',
            font_size='18sp',
            bold=True,
            size_hint_y=None,
            height='40sp',
            color=(0.22, 0.75, 0.97, 1) # Sky blue accent
        )
        self.add_widget(self.title_label)

        # Server IP Configuration Layout
        ip_layout = GridLayout(cols=2, size_hint_y=None, height='50sp', spacing=10)
        ip_layout.add_widget(Label(text='Server IP:', font_size='14sp', bold=True))
        
        self.ip_input = TextInput(
            text='http://46.101.190.76:5000',
            font_size='14sp',
            multiline=False,
            halign='center'
        )
        ip_layout.add_widget(self.ip_input)
        self.add_widget(ip_layout)

        # Connection Status Display
        self.status_label = Label(
            text='Status: Disconnected / Ready to Poll',
            font_size='14sp',
            size_hint_y=None,
            height='40sp',
            color=(0.95, 0.62, 0.04, 1)
        )
        self.add_widget(self.status_label)

        # Telemetry Data Metrics Panel
        metrics_grid = GridLayout(cols=2, spacing=10, size_hint_y=None, height='120sp')
        
        self.dx_label = Label(text='Dx Offset: --', font_size='14sp')
        self.dy_label = Label(text='Dy Offset: --', font_size='14sp')
        self.d4s_label = Label(text='D4σ Width: --', font_size='14sp')
        self.health_label = Label(text='Health (H_k): --', font_size='14sp')

        metrics_grid.add_widget(self.dx_label)
        metrics_grid.add_widget(self.dy_label)
        metrics_grid.add_widget(self.d4s_label)
        metrics_grid.add_widget(self.health_label)
        self.add_widget(metrics_grid)

        # Connect / Toggle Polling Button
        self.connect_btn = Button(
            text='CONNECT & STREAM',
            font_size='16sp',
            bold=True,
            size_hint_y=None,
            height='50sp',
            background_color=(0.02, 0.52, 0.78, 1)
        )
        self.connect_btn.bind(on_press=self.toggle_connection)
        self.add_widget(self.connect_btn)

        # Polling state
        self.is_polling = False

    def toggle_connection(self, instance):
        if not self.is_polling:
            self.is_polling = True
            self.connect_btn.text = 'DISCONNECT'
            self.connect_btn.background_color = (0.85, 0.2, 0.2, 1)
            Clock.schedule_interval(self.poll_telemetry, 1.0)
        else:
            self.is_polling = False
            Clock.unschedule(self.poll_telemetry)
            self.connect_btn.text = 'CONNECT & STREAM'
            self.connect_btn.background_color = (0.02, 0.52, 0.78, 1)
            self.status_label.text = 'Status: Disconnected'

    def poll_telemetry(self, dt):
        threading.Thread(target=self._fetch_data).start()

    def _fetch_data(self):
        base_url = self.ip_input.text.strip()
        try:
            response = requests.get(f"{base_url}/api/telemetry", timeout=2.0)
            if response.status_code == 200:
                data = response.json()
                Clock.schedule_once(lambda dt: self.update_ui_metrics(data))
            else:
                Clock.schedule_once(lambda dt: self.update_status_error("Server Error: HTTP " + str(response.status_code)))
        except Exception as e:
            Clock.schedule_once(lambda dt: self.update_status_error("Connection Failed"))

    def update_ui_metrics(self, data):
        self.status_label.text = 'Status: Connected & Streaming (Active)'
        self.status_label.color = (0.13, 0.77, 0.36, 1)
        self.dx_label.text = f"Dx Offset: {data.get('dx', 0.0):.1f} px"
        self.dy_label.text = f"Dy Offset: {data.get('dy', 0.0):.1f} px"
        self.d4s_label.text = f"D4σ Width: {data.get('d4sigma', 142.0):.1f} px"
        self.health_label.text = f"Health (H_k): {data.get('health', 0.99):.3f}"

    def update_status_error(self, msg):
        self.status_label.text = f"Status: {msg}"
        self.status_label.color = (0.95, 0.3, 0.3, 1)

class AptisApp(App):
    def build(self):
        self.title = "Aptis"
        return AptisRootLayout()

if __name__ == '__main__':
    AptisApp().run()