### Build container
```
docker build -t coreml .
```

### Run container
```
docker run --env PYTHONUNBUFFERED=x coreml
```

### Login to container

```
docker run -t -i coreml /bin/bash
```

### Run the model
```
python test.py
```

### Removing all containers

```
docker rm `docker ps --no-trunc -aq`
```
