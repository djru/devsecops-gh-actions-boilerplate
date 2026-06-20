from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Route
import uvicorn

async def homepage(request):
    return JSONResponse({"status": "active", "message": "Hello from the secure container!"})

async def healthcheck(request):
    return JSONResponse({"status": "OK"})

app = Starlette(routes=[
    Route('/', homepage),
    Route('/health', healthcheck)
])

if __name__ == "__main__":
    # Listen on all interfaces inside the container
    uvicorn.run(app, host="0.0.0.0", port=8000)