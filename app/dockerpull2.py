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
    image_name = container.attrs['Config']['Image']
    registry_url = image_name.split("/")[0]
    repository_name = image_name.split(registry_url + "/")[1].split(":")[0]
    tag = image_name.split(":")[1]
    new_image_name = f"{registry_url}/{repository_name}:{tag}"
    try:
        # Check for new images before stopping the container
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

        # Check if the container is part of a stack
        if container.attrs.get('Labels', {}).get('com.docker.stack.namespace'):
            # Get the stack name and restart the whole stack
            stack_name = container.attrs['Labels']['com.docker.stack.namespace']
            print(f"Container {container_name} is part of stack {stack_name}. Restarting the whole stack...")
            stack_containers = client.containers.list(filters={'label': f'com.docker.stack.namespace={stack_name}'})
            for stack_container in stack_containers:
                # Stop and remove each container in the stack
                print(f"Stopping container {stack_container.name}")
                stack_container.stop()
                print(f"Removing container {stack_container.name}")
                stack_container.remove()
                # Start a new container with the updated image
                print(f"Starting container {stack_container.name} with updated image {new_image_name}")
                client.containers.run(
                    new_image_name,
                    detach=True,
                    name=stack_container.name,
                    ports=stack_container.attrs['HostConfig']['PortBindings'],
                    environment=stack_container.attrs['Config']['Env'],
                    volumes=stack_container.attrs['HostConfig']['Binds'],
                    network_mode=stack_container.attrs['HostConfig']['NetworkMode'],
                    labels=stack_container.labels,
                    stack_name=stack_name,
                    restart_policy={"Name": "unless-stopped"}
                )
        else:
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
                labels=container.labels,
                restart_policy={"Name": "unless-stopped"}
            )

else:
    # Check Get the container's stack name, if it exists
    stack_name = container.attrs['Config']['Labels'].get('com.docker.compose.project')
    if stack_name:
        # Restart the entire stack
        print(f"Restarting stack {stack_name}")
        stack_containers = client.containers.list(filters={"label": f"com.docker.compose.project={stack_name}"})
        for stack_container in stack_containers:
            if stack_container.name not in ignore_containers:
                print(f"Stopping container {stack_container.name}")
                stack_container.stop()
                print(f"Removing container {stack_container.name}")
                stack_container.remove()
                print(f"Starting container {stack_container.name} with updated image {new_image_name}")
                client.containers.run(
                    new_image_name,
                    detach=True,
                    name=stack_container.name,
                    ports=stack_container.attrs['HostConfig']['PortBindings'],
                    environment=stack_container.attrs['Config']['Env'],
                    volumes=stack_container.attrs['HostConfig']['Binds'],
                    network_mode=stack_container.attrs['HostConfig']['NetworkMode'],
                    labels=stack_container.labels
                )

# If no container was specified and no containers were restarted, print a message
if not args.container and not restarted_containers:
    print("No containers were restarted")
