from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def homepage():
    return { }

@app.get("/health")
def homepage():
    return { "health": "ok" }