# Change between backends:

open /Users/spiros/.keras/keras.json

# Problems
Needs keras 1.0

```
conda install -c conda-forge keras=1.1.1
```

# Interpret results

In [http://dl.caffe.berkeleyvision.org/caffe_ilsvrc12.tar.gz](http://dl.caffe.berkeleyvision.org/caffe_ilsvrc12.tar.gz) there is a file called synsets.txt. If you have 285 as the predicted class id, simply go to line 285 in that file and get the synset (which is, in your case, n02123597). If you then want the words corresponding to that synset, look it up in synset_words.txt ("Siamese cat, Siamese").

### Build container
```
docker build -t [name_of_container] .
```

### Run container
```
docker run --env PYTHONUNBUFFERED=x [name_of_container]
```

### Login to container

```
docker run -t -i [name_of_container] /bin/bash
```

### Remove all containers

```
docker rm `docker ps --no-trunc -aq`
```