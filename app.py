from flask import Flask
from datetime import datetime
import os

app = Flask(__name__)
VERSION = "1.0.1"

@app.route('/')
def home():
    return {"status": "ok", "version": VERSION}

@app.route('/time')
def time():
    return {"time": datetime.now().isoformat(), "env": os.getenv("ENV", "dev-env")}

if __name__ == '__main__':
    port = int(os.getenv("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
