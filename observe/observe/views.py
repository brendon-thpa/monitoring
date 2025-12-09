import random
import time
from django.http import HttpResponse

def hello(request):
    return HttpResponse("hello world")

def fetch(request):
    time.sleep(random.uniform(0.2, 10.0))
    return HttpResponse("fetched some data")
