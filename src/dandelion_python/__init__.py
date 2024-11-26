from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/")
async def read_root():
    return {"message": "Hi world!"}

def main():
    uvicorn.run(app, host="0.0.0.0", port=8000)
