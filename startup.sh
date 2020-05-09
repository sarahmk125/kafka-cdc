# Build the Docker image from the Dockerfile
sudo docker build -t 'sample' .

# Run the image
sudo docker run -d sample

# Startup the required containers, defined in this Docker Compose file
docker-compose -f docker-compose-debezium-local.yml up -d
