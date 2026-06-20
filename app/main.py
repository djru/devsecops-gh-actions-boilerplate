from starlette.applications import Starlette
from starlette.responses import JSONResponse, Response
from starlette.routing import Route
import uvicorn

async def homepage(request):
    return JSONResponse({"status": "active", "message": "Hello from the secure container!"})

async def healthcheck(request):
    return JSONResponse({"status": "OK"})

# bad
AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE" 
AWS_SECRET_ACCESS_KEY = "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"

async def unsafe_bad(request):
    # DANGER: Directly evaluating raw user queries allows Remote Code Execution (RCE)
    user_query = request.query_params.get("cmd", "")
    result = eval(user_query) 
    return Response(str(result))

app = Starlette(routes=[
    Route('/', homepage),
    Route('/health', healthcheck),
    Route('/bad', unsafe_bad)
])

if __name__ == "__main__":
    # Listen on all interfaces inside the container
    uvicorn.run(app, host="0.0.0.0", port=8000)