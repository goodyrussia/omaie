import socket, threading, time

LOG_FILE = "/var/log/ws-proxy.log"

def log(msg):
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"[{time.strftime("%Y-%m-%d %H:%M:%S")}] {msg}\n")
    except: pass

def fwd(s, d):
    try:
        while True:
            data = s.recv(8192)
            if not data: break
            d.sendall(data)
    except: pass
    finally:
        for sock in [s, d]:
            try: sock.close()
            except: pass

def handle(c):
    try:
        c.settimeout(5.0)
        data = c.recv(8192)
        c.settimeout(None)
        
        if not data:
            c.close()
            return

        lower_data = data.lower()
        b = socket.socket()
        
        # 1. STRICT PRIORITY: Route Xray protocols FIRST by their exact paths
        if b"get /vmess" in lower_data:
            log("Routing to VMess (Port 10002)")
            b.connect(("127.0.0.1", 10002))
            b.sendall(data)
        elif b"get /trojan" in lower_data:
            log("Routing to Trojan (Port 10003)")
            b.connect(("127.0.0.1", 10003))
            b.sendall(data)
        elif b"get /xray" in lower_data or b"get / " in lower_data:
            log("Routing to VLESS/Xray (Port 10001)")
            b.connect(("127.0.0.1", 10001))
            b.sendall(data)
        
        # 2. SSH / SSL / Custom Payloads SECOND
        elif b"connect" in lower_data:
            log("Routing SSH CONNECT (Port 22)")
            c.sendall(b"HTTP/1.1 200 Connection Established\r\n\r\n")
            b.connect(("127.0.0.1", 22))
            parts = data.split(b"\r\n\r\n", 1)
            if len(parts) > 1 and parts[1]:
                b.sendall(parts[1])
        elif b"upgrade: websocket" in lower_data:
            log("Routing SSH WebSocket (Port 22)")
            c.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
            b.connect(("127.0.0.1", 22))
            parts = data.split(b"\r\n\r\n", 1)
            if len(parts) > 1 and parts[1]:
                b.sendall(parts[1])
        else:
            log("Routing SSH Fallback (Port 22)")
            b.connect(("127.0.0.1", 22))
            b.sendall(data)

        threading.Thread(target=fwd, args=(c, b), daemon=True).start()
        threading.Thread(target=fwd, args=(b, c), daemon=True).start()
    except Exception as e:
        log(f"Error: {e}")
        try: c.close()
        except: pass

s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", 8880)); s.listen(200)
log("WS-Proxy started on port 8880")
while True:
    c, _ = s.accept()
    threading.Thread(target=handle, args=(c,), daemon=True).start()
