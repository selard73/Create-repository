"""Tiny localhost receiver: Studio POSTs a mesh dump to http://127.0.0.1:34991/<name>; the body is saved as <outdir>/<name>.txt.
Run: python mesh_receiver.py <outdir>   (stops after 30 minutes)"""
import http.server, os, sys, threading
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        name = os.path.basename(self.path.strip("/")) or "dump"
        n = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(n)
        with open(os.path.join(OUT, name + ".txt"), "wb") as f: f.write(body)
        self.send_response(200); self.end_headers(); self.wfile.write(f"saved {name} {len(body)} bytes".encode())
        print(f"saved {name} {len(body)} bytes", flush=True)
    def log_message(self, *a): pass
srv = http.server.HTTPServer(("127.0.0.1", 34991), H)
threading.Timer(1800, srv.shutdown).start()
print("listening", flush=True)
srv.serve_forever()
