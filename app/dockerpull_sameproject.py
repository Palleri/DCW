import docker
import time
import argparse

# Connect to the Docker API
client = docker.DockerClient(base_url='unix://var/run/docker.sock')

# List of container names to ignore
ignore_containers = ['dcw']

# Get the hostname of the container on which the script is running
with open('/etc/hostname', 'r') as f:
    container_id = f.read().strip()

# Add the container ID to the list of containers to ignore
ignore_containers.append(container_id)

parser = argparse.ArgumentParser(description='Check for updated Docker images and restart containers as needed')
parser.add_argument('--container', help='Name of the container to check for updates and restart (optional)')
args = parser.parse_args()

if args.container:
    # Check for updates and restart the specified container
    container_name = args.container
    container = client.containers.get(container_name)

    # Check if there are other containers with the same working_dir
    project_dir = container.attrs['Config']['Labels']['com.docker.compose.project.working_dir']
    project_containers = [c for c in client.containers.list() if c.id != container.id and 
                          c.attrs['Config']['Labels'].get('com.docker.compose.project.working_dir') == project_dir]

    # Check for new images before stopping the container
    image_name = container.attrs['Config']['Image']
    registry_url = image_name.split("/")[0]
    repository_name = image_name.split(registry_url + "/")[1].split(":")[0]
    tag = image_name.split(":")[1]
    new_image_name = f"{registry_url}/{repository_name}:{tag}"
    try:
        client.images.pull(new_image_name)
    except docker.errors.ImageNotFound:
        print(f"No new image found for container {container_name}")
    else:
        # Stop the container
        print(f"Stopping container {container_name}")
        container.stop()

        # Remove the container
        print(f"Removing container {container_name}")
        container.remove()

        # Start a new container with the updated image
        print(f"Starting container {container_name} with updated image {new_image_name}")
        client.containers.run(
            new_image_name,
            detach=True,
            name=container_name,
            ports=container.attrs['HostConfig']['PortBindings'],
            environment=container.attrs['Config']['Env'],
            volumes=container.attrs['HostConfig']['Binds'],
            network_mode=container.attrs['HostConfig']['NetworkMode'],
            labels=container.labels
        )

        # Restart all project containers without updating their image
        for c in project_containers:
            print(f"Restarting container {c.name} without updating its image")
            c.restart()

else:
    print("No input")
    exit()

# Wait for containers to start
time.sleep(3)
