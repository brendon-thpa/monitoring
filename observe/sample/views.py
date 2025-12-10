import random
import time
import json
from django.http import JsonResponse, HttpResponse, HttpResponseBadRequest, HttpResponseServerError
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import (
    BatchSpanProcessor,
    ConsoleSpanExporter,
)
from sample.models import SampleModel

trace.set_tracer_provider(TracerProvider())

trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(ConsoleSpanExporter())
)

def create_sample_model(request):
    try:
        body_data = json.loads(request.body.decode("utf-8"))
        name = body_data.get("name")
        value = body_data.get("value")
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    count = SampleModel.objects.count()
    
    # name = payload.get('name')
    # value = payload.get('value')
    name = f"{name}-{count + 1}"
    sample = SampleModel.objects.create(name=name, value=value)
    sample.save()
    return HttpResponse(JsonResponse({'success': 'created sample model with id ' + str(sample.id)}))
