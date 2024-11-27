import network
import usocket as socket
import urequests as requests
import machine
import ujson as json
import utime
import uos
import urandom
import ubinascii
import gc

SERVER_ENDPOINTS = {
    "register": "/register/",
    "commands": "/api/commands/",
    "devices": "/api/devices/add/",
}

CONFIG_FILE = "conf.txt"
HEADERS = {"Content-Type": "application/json"}
DATA_PAYLOAD = {
    "name": "Pico1",
    "data": {
        "components": [
            {
                "name": "LED",
                "actions": ["on", "off", "toggle"],
                "has_input_action": True,
                "is_output": False,
            },
            {
                "name": "Movement detector",
                "actions": ["detected"],
                "has_input_action": True,
                "is_output": True,
            },
        ]
    },
}

led = machine.Pin("LED", machine.Pin.OUT)
pir = machine.Pin(16, machine.Pin.IN)
last_time = 0
config = {}


def movement_handler(_):
    gc.collect()
    global last_time
    new_time = utime.ticks_ms()
    if utime.ticks_diff(new_time, last_time) > 60000:
        last_time = new_time
        create_command({"name": "Movement detector", "action": "detected"})


def get_udp_config():
    ap = network.WLAN(network.AP_IF)
    ap.config(essid="HomeLinkDevice", password="12345678")
    ap.active(True)

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.bind(("0.0.0.0", 12345))
        data, _ = sock.recvfrom(1024)
        config.update(json.loads(data))
        config["password"] = "".join(
            [chr(urandom.getrandbits(7) % 26 + 97) for _ in range(12)]
        )

    ap.active(False)
    gc.collect()


def connect_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    wlan.connect(config["wifi"]["ssid"], config["wifi"]["password"])

    timeout = utime.time() + 10
    while not wlan.isconnected() and utime.time() < timeout:
        utime.sleep(1)

    if not wlan.isconnected():
        raise RuntimeError("WiFi connection failed")


def make_request(method, endpoint, data=None):
    gc.collect()
    url = config["server_url"] + endpoint
    try:
        if method == "GET":
            return requests.get(url, headers=HEADERS)
        elif method == "POST":
            return requests.post(url, json=data, headers=HEADERS)
        elif method == "DELETE":
            return requests.delete(url, headers=HEADERS)
    except Exception as e:
        print(f"Request error ({method} {url}):", e)
        return None


def register_device():
    device_name = config["username"] + "".join(
        [chr(urandom.getrandbits(7) % 26 + 97) for _ in range(8)]
    )
    response = make_request(
        "POST",
        SERVER_ENDPOINTS["register"],
        {
            "username": device_name,
            "password": config["password"],
            "user": config["username"],
        },
    )

    if response and response.status_code == 201:
        data = response.json()
        config.update({"account_id": data["id"], "username": device_name})
        save_config()
        set_auth_headers()
        response.close()


def process_command(cmd):
    data = cmd["data"]
    if data["name"] == "LED":
        if data["action"] == "on":
            led.on()
        elif data["action"] == "off":
            led.off()
        elif data["action"] == "toggle":
            led.toggle()


def check_commands(_):
    gc.collect()
    response = make_request("GET", SERVER_ENDPOINTS["commands"] + "get/")
    if response and response.status_code == 200:
        commands = response.json()
        response.close()

        for cmd in commands:
            process_command(cmd)
            del_response = make_request(
                "DELETE", f"{SERVER_ENDPOINTS['commands']}{cmd['id']}/"
            )
            if del_response:
                del_response.close()


def create_command(data):
    make_request(
        "POST",
        SERVER_ENDPOINTS["commands"],
        {"description": "Auto created", "data": data, "self_execute": True},
    )


def set_auth_headers():
    auth = (
        ubinascii.b2a_base64(f"{config['username']}:{config['password']}".encode())
        .decode()
        .strip()
    )
    HEADERS["Authorization"] = f"Basic {auth}"


def save_config():
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f)


def load_config():
    try:
        with open(CONFIG_FILE, "r") as f:
            config.update(json.loads(f.read()))
        return True
    except OSError:
        return False


def main():
    gc.enable()
    gc.collect()

    if not load_config():
        get_udp_config()

    connect_wifi()

    if "account_id" not in config:
        register_device()
        DATA_PAYLOAD["account"] = config["account_id"]
        resp = make_request("POST", SERVER_ENDPOINTS["devices"], DATA_PAYLOAD)
        if resp:
            resp.close()

    pir.irq(trigger=machine.Pin.IRQ_RISING, handler=movement_handler)
    timer = machine.Timer()
    timer.init(period=1000, mode=machine.Timer.PERIODIC, callback=check_commands)


if __name__ == "__main__":
    main()
