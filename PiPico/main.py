import network
import usocket as socket
import urequests as requests
import machine
import ujson as json
from time import sleep
import utime
import uos as os
import urandom as random
import ubinascii

led = machine.Pin("LED", machine.Pin.OUT)
led.off()
last_time = 0


def movement_detector_handler(_):
    global last_time
    new = utime.ticks_ms()
    if (new - last_time) > 1000:
        last_time = new
        create_command({"name": "Movement detector", "action": "detected"})


# TODO actual movement detector
button = machine.Pin(14, machine.Pin.IN, machine.Pin.PULL_DOWN)
button.irq(trigger=machine.Pin.IRQ_FALLING, handler=movement_detector_handler)


SSID = None
WIFI_PASSWORD = None
SERVER_URL = None
USERNAME = None
PASSWORD = None
ACCOUNT_ID = None


def get_conf_udp():
    """Get configuration from UDP broadcast message and set global variables.
    `ap.active(False)` "resets" AP
    """
    global SSID, WIFI_PASSWORD, SERVER_URL, USERNAME, PASSWORD

    ap = network.WLAN(network.AP_IF)
    ap.config(essid="HomeLinkDevice", password="12345678")
    ap.active(False)
    sleep(1)
    ap.active(True)

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("0.0.0.0", 12345))
    print("Listening on port 12345...")
    data, _ = sock.recvfrom(1024)
    payload = json.loads(data)

    SSID = payload["wifi"]["ssid"]
    WIFI_PASSWORD = payload["wifi"]["password"]
    SERVER_URL = payload["server_url"]
    USERNAME = payload["username"]
    PASSWORD = random_characters()
    ap.active(False)


def connect_to_wifi():
    """Connects to home WiFi using configuration from client's UDP broadcast message (1st time) or from file.
    It prints MAC address of the device after successful connection.
    """
    if not SSID or not WIFI_PASSWORD:
        return
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    wlan.connect(SSID, WIFI_PASSWORD)
    print(SSID, WIFI_PASSWORD)
    while not wlan.isconnected():
        print("Connecting to WiFi...")
        sleep(1)
    print(
        ":".join(
            ["{:02x}".format(b) for b in network.WLAN(network.STA_IF).config("mac")]
        )
    )


def register_pico():
    """Creates Django user account to authenticate future requests.
    Generates random device name based on owner's username.
    Account ID is saved to a file for future use in creating Device objects.
    """
    global ACCOUNT_ID, USERNAME, PASSWORD

    response = None
    device_name = USERNAME + random_characters()
    print({"username": device_name, "password": PASSWORD, "user": USERNAME})

    try:
        response = requests.post(
            SERVER_URL + "/register/",
            json={"username": device_name, "password": PASSWORD, "user": USERNAME},
        )
    except Exception as e:
        print("Exception", e)

    if response and response.status_code == 201:
        ACCOUNT_ID = response.json()["id"]
        USERNAME = device_name
        PASSWORD = PASSWORD
        with open("conf.txt", "w") as file:
            file.write(
                json.dumps(
                    {
                        "wifi": {"ssid": SSID, "password": WIFI_PASSWORD},
                        "server_url": SERVER_URL,
                        "username": device_name,
                        "password": PASSWORD,
                        "account_id": ACCOUNT_ID,
                    }
                )
            )
        print("Device registered successfully")
    else:
        print(
            "Failed to register device. Status code:",
            response.status_code if response else "No response",
        )


DATA_PAYLOAD = {
    "name": "Pico1",
    "data": {
        "components": [
            {"name": "LED", "actions": ["on", "off", "toggle"]},
            {"name": "Movement detector", "actions": ["detected"]},
        ]
    },
}


def perform_actions(data):
    """Performs actions on components attached to the PiPico.

    Args:
        data (list): Information about the component and actions to perform.
        Can look like this:
        {
            "name": "LED",
            "action": ["on"]
        }
    """
    print(data)
    if data["name"] == "LED":
        if data["action"] == "on":
            led.on()
        elif data["action"] == "off":
            led.off()
        elif data["action"] == "toggle":
            led.toggle()


def get_commands():
    """Gets list of potential Commands from the server and performs them.
    If the command is performed successfully, it is deleted from the server.
    """
    while True:
        try:
            headers = {"Content-Type": "application/json"}
            auth_string = f"{USERNAME}:{PASSWORD}"
            auth_bytes = auth_string.encode("ascii")
            base64_bytes = ubinascii.b2a_base64(auth_bytes)
            base64_auth = base64_bytes.decode("ascii").strip()
            headers["Authorization"] = f"Basic {base64_auth}"

            request = requests.get(SERVER_URL + f"/api/commands/get/", headers=headers)
            if request.status_code == 200:
                data = request.json()
                for command in data:
                    perform_actions(command["data"])
                    requests.delete(
                        f"{SERVER_URL}/api/commands/{command['id']}/", headers=headers
                    )
            else:
                print("Failed to get commands. Status code:", request.status_code)
            sleep(5)
        except Exception as e:
            print("Exception", e)
            sleep(5)


def define_devices():
    """Creates instance of Device model on the server.
    Uses basic authentication in headers (auth param for requests.post is not supported).
    DATA_PAYLOAD represents capabilities of the components attached to the PiPico.
    """
    DATA_PAYLOAD["account"] = ACCOUNT_ID
    headers = {"Content-Type": "application/json"}
    auth_string = f"{USERNAME}:{PASSWORD}"
    auth_bytes = auth_string.encode("ascii")
    base64_bytes = ubinascii.b2a_base64(auth_bytes)
    base64_auth = base64_bytes.decode("ascii").strip()
    headers["Authorization"] = f"Basic {base64_auth}"

    request = requests.post(
        SERVER_URL + "/api/devices/add/", json=DATA_PAYLOAD, headers=headers
    )

    if request.status_code == 201:
        print("Device defined successfully")
    else:
        print("Failed to define device. Status code:", request.status_code)


def create_command(data):
    """Creates a self executed command - input from the device to the system

    Args:
        data ({"name": componentName, "action": action}): command data
    """
    headers = {"Content-Type": "application/json"}
    auth_string = f"{USERNAME}:{PASSWORD}"
    auth_bytes = auth_string.encode("ascii")
    base64_bytes = ubinascii.b2a_base64(auth_bytes)
    base64_auth = base64_bytes.decode("ascii").strip()
    headers["Authorization"] = f"Basic {base64_auth}"

    command_data = {
        "description": "Auto created",
        "data": data,
        "self_execute": True,
    }

    requests.post(SERVER_URL + "/api/commands/", json=command_data, headers=headers)


def file_exists(filename):
    """Used to check if a file exists.
    File can be a configuration file.

    Args:
        filename (str): Name of the file to check.

    Returns:
        bool: Whether the file exists or not.
    """
    try:
        os.stat(filename)
        return True
    except OSError:
        return False


def random_characters(length=12):
    """Yes, it generates random characters.

    Args:
        length (int, optional): Length of the string to generate. Defaults to 12.

    Returns:
        str: Random string of specified length.
    """
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
    return "".join(chars[random.getrandbits(6) % len(chars)] for _ in range(length))


if __name__ == "__main__":
    registered = file_exists("conf.txt")
    print("registered: ", registered)

    if not registered:
        get_conf_udp()
    else:
        with open("conf.txt", "r") as file:
            data = file.read()
            data = json.loads(data)
            SSID = data["wifi"]["ssid"]
            WIFI_PASSWORD = data["wifi"]["password"]
            SERVER_URL = data["server_url"]
            USERNAME = data["username"]
            PASSWORD = data["password"]
            ACCOUNT_ID = data["account_id"]

    connect_to_wifi()

    if not registered:
        register_pico()
        define_devices()

    get_commands()
