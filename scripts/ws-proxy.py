import socket, threading
def handle(client):
    try:
        req = client.recv(4096).decode('utf-8', 'ignore')
        if not req: return
        
        # Standard WebSocket handshake accepted by SSH Custom
        client.send(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
        
        ssh = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh.connect(('127.0.0.1', 22))
        
        def forward(s, d):
            try:
                while True:
                    data = s.recv(4096)
                    if not data: break
                    d.send(data)
            except: pass
            finally:
                s.close()
                d.close()
                
        threading.Thread(target=forward, args=(client, ssh), daemon=True).start()
        threading.Thread(target=forward, args=(ssh, client), daemon=True).start()
    except: pass

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('127.0.0.1', 8880))
s.listen(100)
while True:
    c, _ = s.accept()
    threading.Thread(target=handle, args=(c,)).start()
