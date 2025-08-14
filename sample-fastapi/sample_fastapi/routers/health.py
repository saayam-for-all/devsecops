from fastapi import APIRouter, HTTPException, Request, status, Response
import json
router = APIRouter()

@router.get("/liveness")
async def liveness(request:Request):
    return Response(content=json.dumps({"status":"healthy"}),status_code=status.HTTP_200_OK)
