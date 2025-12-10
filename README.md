# Test App for Instrumenting systems

## Setup
- Install Requirements.txt
- Install Prometheus and Grafana - wiki.txt *Grafan install needs amending
- Add Django endpoint to Prometheus.yml settings

## Running
Prometheus and Grafana can be run using the start_pro_graf.ps1 script
Django with instrumentation needs `opentelemetry-instrument python manage.py runserver --noreload`

