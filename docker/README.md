### Build the container
```
docker build -t coreml .
```

### Run the container
```
docker run --env PYTHONUNBUFFERED=x coreml
```

### Login to the container

```
docker run -t -i coreml /bin/bash
```

### Run the model
```
python test.py
```

### Removing all the containers

```
docker rm `docker ps --no-trunc -aq`
```
