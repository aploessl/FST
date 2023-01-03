#FROM gcr.io/google-appengine/python

# Create a virtualenv for dependencies. This isolates these packages from
# system-level packages.
# Use -p python3 or -p python3.7 to select python version. Default is version 2.
#RUN virtualenv /env

# Setting these environment variables are the same as running
# source /env/bin/activate.
#ENV VIRTUAL_ENV /env
#ENV PATH /env/bin:$PATH

# Copy the application's requirements.txt and run pip to install all
# dependencies into the virtualenv.
#ADD requirements.txt /app/requirements.txt
#RUN pip install -r /app/requirements.txt

# Add the application source code.
#ADD . /app

# Run a WSGI server to serve the application. gunicorn must be declared as
# a dependency in requirements.txt.
#CMD gunicorn -b :$PORT main:app


# Stage 1: Builder/Compiler
FROM python:3.8-slim as builder
RUN apt update && \
    apt install --no-install-recommends -y build-essential gcc
COPY requirements.txt /requirements.txt

RUN pip install --no-cache-dir --user -r /requirements.txt

# Stage 2: Runtime
FROM nvidia/cuda:10.1-cudnn7-runtime

RUN apt update && \
    apt install --no-install-recommends -y build-essential software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt install --no-install-recommends -y python3.8 python3-distutils && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2 && \
    apt clean && rm -rf /var/lib/apt/lists/*
COPY --from=builder /root/.local/lib/python3.8/site-packages /usr/local/lib/python3.8/dist-packages
COPY ./src /src
CMD ['python3', '/src/app.py']
EXPOSE 8080
