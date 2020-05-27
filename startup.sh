# Build the Docker image from the Dockerfile
docker build -t 'sample' .

# Run the image
docker run -d sample

# Build the dependent images
docker-compose -f docker-compose-debezium-local.yml build

# Startup the required containers, defined in this Docker Compose file
docker-compose -f docker-compose-debezium-local.yml up -d
