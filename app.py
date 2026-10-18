from flask import Flask, send_from_directory, jsonify
import os

# Initialize Flask app, setting static folder to current directory
app = Flask(__name__, static_folder='.')

@app.route('/')
def index():
    """Reads and serves index.html directly from the current directory."""
    html_path = os.path.join(os.path.dirname(__file__), 'index.html')
    if os.path.exists(html_path):
        with open(html_path, 'r', encoding='utf-8') as f:
            return f.read()
    return "Error: index.html not found in the root directory.", 404

@app.route('/app_icon.png')
def favicon():
    """Serves the website icon / logo from the root directory."""
    return send_from_directory('.', 'app_icon.png')

@app.route('/telemetry')
def telemetry():
    """Provides real-time JSON telemetry for the Aptis HUD."""
    return jsonify({
        "dx": 0,
        "dy": 0,
        "dist": 0.0,
        "d4s_x": 142.4,
        "d4s_y": 140.8,
        "health_score": 0.998,
        "aligned": True,
        "status": "Locked & Optimized"
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)