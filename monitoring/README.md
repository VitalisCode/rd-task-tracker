# Monitoring Stack Overview

This directory contains Helm chart configurations for a complete observability stack. Below is an explanation of each component and how they work together.

---

## Architecture Flow

```
Containers (Logs)
      ↓
   Filebeat (Log Shipper)
      ↓
   Logstash (Log Processor & Parser)
      ↓
   Elasticsearch / Loki (Log Storage)
      ↓
   Kibana / Grafana (Visualization & Querying)
```

---

## Components

### 1. **Filebeat** (`filebeat/`)

**Purpose:** Log collection and shipping agent

**What it does:**
- Runs as a DaemonSet on every Kubernetes node
- Collects container logs from stdout/stderr
- Reads application logs in real-time
- Sends logs to Logstash for processing
- Lightweight and efficient log forwarder

**Configuration:** `values.yaml`
- Specifies input sources (container logs, files)
- Defines output destination (Logstash endpoint: `logstash:5044`)
- Contains collection rules and filters

**When to use:** Always deploy if you need to collect pod/container logs

---

### 2. **Logstash** (`logstash/`)

**Purpose:** Log processing, parsing, and enrichment pipeline

**What it does:**
- Receives raw logs from Filebeat on port 5044
- **Parses** unstructured logs into structured data
  - Converts JSON strings to structured fields
  - Extracts log level, message, timestamp
- **Enriches** logs with Kubernetes metadata
  - Adds pod name, namespace, container name
  - Adds cluster context
- **Filters** and transforms logs
- Sends processed logs to Elasticsearch or other output

**Configuration:** `logstash.conf`
- **input block:** Receives Beats protocol on port 5044
- **filter block:** Parses JSON, extracts fields, adds metadata
- **output block:** Sends to Elasticsearch (or configured destination)

**Example transformation:**
```
Input:  {"time": "2026-06-12T10:30:45", "level": "INFO", "message": "Task created"}
Output: {
  log_time: "2026-06-12T10:30:45",
  log_level: "INFO",
  log_message: "Task created",
  k8s_namespace: "rd-staging",
  k8s_pod: "api-pod-abc123",
  k8s_container: "api"
}
```

**When to use:** Deploy if you need to parse and enrich logs before storage

---

### 3. **Kibana** (`kibana/`)

**Purpose:** Web UI for searching, analyzing, and visualizing Elasticsearch logs

**What it does:**
- Provides a web dashboard to query logs
- Allows searching logs by keyword, timestamp, field
- Creates log visualizations and dashboards
- Analyzes log patterns and trends
- Sends queries to Elasticsearch backend

**Configuration:** `values.yaml`
- Elasticsearch connection details
- Authentication settings
- UI customization

**Access:**
```bash
kubectl port-forward svc/kibana 5601:5601
# Open http://localhost:5601 in browser
```

**When to use:** Deploy if you're using Elasticsearch as your log storage backend

---

### 4. **Grafana** (`grafana/`)

**Purpose:** Multi-purpose visualization and dashboarding platform

**What it does:**
- Connects to multiple data sources (Loki, Prometheus, Elasticsearch)
- Creates dashboards to visualize metrics and logs
- Auto-provisions Loki and Prometheus as data sources on startup
- Hosts pre-built custom dashboards
- Provides alerting capabilities

**Configuration:** `values.yaml`
- Auto-configures Loki datasource (default): queries logs from Loki
- Auto-configures Prometheus datasource: queries metrics
- Enables dashboard auto-provisioning
- Sets admin credentials

**Dashboards:** `dashboards/`
- `rd-tracker.json` — Custom dashboard for the R&D task tracker
  - Shows logs from the API
  - Displays performance metrics
  - Visualizes task status and trends

**Access:**
```bash
kubectl port-forward svc/grafana 3000:3000
# Open http://localhost:3000
# Default login: admin / admin123 (from values.yaml)
```

**When to use:** Deploy for visualization of both logs (via Loki) and metrics (via Prometheus)

---

### 5. **Loki** (`loki/`)

**Purpose:** Lightweight log aggregation and storage (alternative to Elasticsearch)

**What it does:**
- Stores logs efficiently with minimal resource overhead
- Designed specifically for Kubernetes and container logs
- Uses label-based indexing (namespace, pod, container) instead of full-text indexing
- Faster queries for container-native data
- Integrates seamlessly with Grafana

**Configuration:** `values.yaml`
- Storage backend (local, S3, GCS, etc.)
- Retention policies
- Scrape configs (which logs to ingest)
- Persistence settings (stores logs on disk/volume)

**Why Loki instead of Elasticsearch?**
- Lighter on resources (CPU, memory, disk)
- Better suited for Kubernetes environments
- Cheaper to operate
- Simpler label-based querying

**When to use:** Deploy if you want log storage with lower overhead than Elasticsearch

---

## Common Deployment Scenarios

### Scenario 1: **Full ELK Stack** (Enterprise logging)
```
Filebeat → Logstash → Elasticsearch ← Kibana
                                   ← Grafana
```
- Use: Large-scale, high-volume logging
- Tools: Filebeat + Logstash + Elasticsearch + Kibana
- Cost: High resource usage
- Best for: Complex log analysis, full-text search

---

### Scenario 2: **Loki + Grafana** (Cloud-native, lightweight)
```
Filebeat → Logstash → Loki ← Grafana
```
- Use: Kubernetes-first environments
- Tools: Filebeat + Logstash + Loki + Grafana
- Cost: Low resource usage
- Best for: Container/pod-level observability

---

### Scenario 3: **Just Grafana + Prometheus** (Metrics only)
```
Prometheus → Grafana (dashboards & alerts)
```
- Use: Monitoring system performance
- Tools: Prometheus + Grafana
- Cost: Minimal
- Best for: Infrastructure and application metrics

---

## How They Connect in This Repo

**Current setup (based on configurations):**

1. **Filebeat** collects pod logs
2. **Logstash** parses and enriches with Kubernetes metadata
3. **Output:** Logs go to configured destination (likely Elasticsearch or Loki)
4. **Grafana** auto-connects to:
   - **Loki** (via datasource config in `grafana/values.yaml`)
   - **Prometheus** (via datasource config in `grafana/values.yaml`)
5. **Kibana** connects to Elasticsearch (if used)
6. **Custom dashboard** (`rd-tracker.json`) displays app-specific logs and metrics

---

## Deployment Commands

```bash
# Deploy entire monitoring stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Deploy each component
helm install filebeat prometheus-community/filebeat -f monitoring/filebeat/values.yaml
helm install logstash prometheus-community/logstash -f monitoring/logstash/values.yaml
helm install loki grafana/loki-stack -f monitoring/loki/values.yaml
helm install grafana grafana/grafana -f monitoring/grafana/values.yaml
helm install kibana prometheus-community/kibana -f monitoring/kibana/values.yaml
```

---

## Access Points

| Component | URL | Purpose |
|-----------|-----|---------|
| Grafana | `http://localhost:3000` | View dashboards, logs, metrics |
| Kibana | `http://localhost:5601` | Search and analyze Elasticsearch logs |
| Loki | `http://localhost:3100` | Direct log queries (usually via Grafana) |
| Logstash | `0.0.0.0:5044` | Receives logs from Filebeat (internal only) |
| Filebeat | N/A | Log collection agent (runs on nodes) |

---

## Troubleshooting

**No logs appearing in Grafana?**
- Check Filebeat is running: `kubectl get pods -l app=filebeat`
- Verify Logstash is processing: `kubectl logs -l app=logstash`
- Confirm Loki has logs: `kubectl logs -l app=loki`

**Logstash crashing?**
- Check configuration syntax in `logstash.conf`
- Verify Elasticsearch/Loki connection string

**High resource usage?**
- Switch from ELK to Loki for lower overhead
- Adjust retention policies in `values.yaml` files
- Reduce log collection verbosity in Filebeat

---

## Next Steps

1. Review each `values.yaml` to understand current configuration
2. Deploy the stack incrementally (start with Grafana + Loki)
3. Customize dashboards in `grafana/dashboards/`
4. Set up log retention policies
5. Configure alerting rules
