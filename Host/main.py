from flask import Flask, jsonify
from flask_cors import CORS
import serial
import json
import time
from threading import Lock
from functools import wraps

app = Flask(__name__)
cors = CORS(app, resources={r"/*": {"origins": "*"}})
lock = Lock()

arduino = serial.Serial('COM3', 9600, timeout=1)
time.sleep(2) 

def with_arduino_lock(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        with lock:
            return func(*args, **kwargs)
    return wrapper

def read_from_arduino():
    line = bytearray()
    while arduino.in_waiting > 0 or not line:
        line.extend(arduino.read(arduino.in_waiting or 1))
    return line.decode().strip()

@app.route('/devices', methods=['GET'])
@with_arduino_lock
def get_devices():
    arduino.write(b'get_status\n')
    time.sleep(1)
    line = read_from_arduino()
    return jsonify(json.loads(line))

@app.route('/device/<id>', methods=['POST'])
@with_arduino_lock
def toggle_device(id):
    arduino.write(f'toggle_{id}\n'.encode())
    time.sleep(1)
    line = read_from_arduino()
    return jsonify(json.loads(line))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=2137, threaded=True)
