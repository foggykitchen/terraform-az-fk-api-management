import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)


@app.function_name(name="fncustom1")
@app.route(route="fncustom1", methods=["POST"])
def fncustom1(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse("fncustom1", status_code=200)


@app.function_name(name="fncustom2")
@app.route(route="fncustom2", methods=["POST"])
def fncustom2(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse("fncustom2", status_code=200)
