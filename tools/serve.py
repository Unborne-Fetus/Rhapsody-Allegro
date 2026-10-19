"""Optional local browser test server. Hosted play needs no installation."""
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from functools import partial
from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('--port',type=int,default=8060);args=p.parse_args()
root=Path(__file__).resolve().parents[1]/'dist'
print(f'Play at http://localhost:{args.port}',flush=True)
ThreadingHTTPServer(('127.0.0.1',args.port),partial(SimpleHTTPRequestHandler,directory=str(root))).serve_forever()
