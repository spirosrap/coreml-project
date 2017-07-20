# Use an official Python runtime as a parent image
FROM python:2.7.13

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD . /app

# Install any needed packages specified in requirements.txt
RUN pip install -r requirements.txt
RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "vim"]
RUN apt-get install wget
RUN wget "https://dl.dropbox.com/s/kbqydhd1s5xqu6k/vgg16_weights.h5"

# Make port 80 available to the world outside this container
# EXPOSE :80

# Define environment variable
ENV NAME World
ENV PYTHONUNBUFFERED x

# Run app.py when the container launches
CMD ["python", "test.py"]
