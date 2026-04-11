# ElasticsearchCheck

## Purpose

Verifies that Elasticsearch is properly configured and reachable before deployment.
This check is especially important for applications using `elasticsearch`, `searchkick`, or `chewy`.

## What It Checks

1. **URL configured** — Looks for `ELASTICSEARCH_URL`, `BONSAI_URL`, or `SEARCHBOX_URL` environment variables.
2. **URL format** — Validates the URL is a properly formed HTTP/HTTPS URI.
3. **Port** — Warns if the port is not the standard Elasticsearch port (9200 or 9243).
4. **Reachability** — Attempts an HTTP `GET /` request and validates a 200 response.

## Configuration

```ruby
RailsDeployCheck.configure do |config|
  config.checks[:elasticsearch] = {
    url: "http://localhost:9200",  # overrides ENV lookup
    timeout: 5,                    # seconds (default: 5)
    required: true                 # error if no URL found (default: false)
  }
end
```

## Auto-detection

The check is automatically registered when:
- Any of `ELASTICSEARCH_URL`, `BONSAI_URL`, or `SEARCHBOX_URL` is set, **or**
- `Gemfile.lock` contains `elasticsearch`, `searchkick`, or `chewy`.

## Result Levels

| Situation | Level |
|---|---|
| URL not set, not required | info |
| URL not set, required | error |
| Malformed URL | error |
| Non-standard port | warning |
| Connection refused | error |
| Connection timeout | error |
| HTTP non-200 response | warning |
| Reachable and healthy | info |
