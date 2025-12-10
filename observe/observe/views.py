import random
import time
from django.http import JsonResponse, HttpResponse, HttpResponseBadRequest, HttpResponseServerError
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import (
    BatchSpanProcessor,
    ConsoleSpanExporter,
)

trace.set_tracer_provider(TracerProvider())

trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(ConsoleSpanExporter())
)

def hello(request):
    return HttpResponse("hello world")

def fetch(request):
    time.sleep(random.uniform(0.2, 10.0))
    return HttpResponse("fetched some data")


def health(request):
    return JsonResponse({'ok': True})

def error_500(request):
    # Intentionally return 500 without raising
    return HttpResponseServerError(JsonResponse({'error': 'Intentional 500'}))

def raise_error(request):
    # Intentionally raise an exception to trigger Django 500 handler
    raise RuntimeError("Intentional server-side exception for testing")

def random_error(request):
    fail = random.random() < 0.2  # ~20% failure rate
    if fail:
        return HttpResponseServerError(JsonResponse({'error': 'Random failure'}))
    return JsonResponse({'ok': True, 'msg': 'Success'})

def timeout(request):
    time.sleep(3)  # simulate slowness
    return JsonResponse({'slow': True})

def bad_request(request):
    return HttpResponseBadRequest(JsonResponse({'error': 'Intentional bad request'}))

def redirect(request):
    return HttpResponse(status=302)