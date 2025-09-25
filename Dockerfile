# Stage 1: The build environment
# Use a public Lambda image that matches your desired Python version.
# For Python 3.13 and newer, Amazon Linux 2023 uses 'dnf' as the package manager.
# Use 'yum' for Python 3.12 and older (based on Amazon Linux 2).
FROM public.ecr.aws/lambda/python:3.13 AS builder

# Install the 'zip' utility
RUN dnf install -y zip

# Create the directory structure for the Lambda layer
RUN mkdir -p /opt/python

# Install psycopg2-binary into the layer directory
# --target ensures it's installed to /opt/python
# --platform manylinux2014_x86_64 ensures binary compatibility with Lambda
# --python-version 3.13 specifies the Python version
# --only-binary=:all: avoids source builds which require more dev tools
RUN pip install --platform manylinux2014_x86_64 --target /opt/python --python-version 3.13 --only-binary=:all: psycopg2-binary

# Create a zip file containing the layer content
RUN cd /opt && zip -r /psycopg2-layer.zip .

# Stage 2: The final, minimal image
# This stage is for packaging only; it creates a tiny image with just the zip file.
FROM scratch

# Copy the zip file from the 'builder' stage to the final image
COPY --from=builder /psycopg2-layer.zip /psycopg2-layer.zip