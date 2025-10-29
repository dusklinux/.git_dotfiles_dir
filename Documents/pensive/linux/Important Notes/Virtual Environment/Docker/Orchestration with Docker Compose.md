Orchestration with Docker Compose

### The Problem: Juggling Many Containers
Real applications often have multiple parts (e.g., a website, a database, a caching service). Managing them with individual `docker run` commands is tedious and error-prone.

### The Solution: Docker Compose
Docker Compose is a tool that uses a single YAML file (`docker-compose.yml`) to define and run an entire multi-container application.

*   **Installation:** `sudo pacman -S --needed docker-compose`
*   **The Manifest:** You create a `docker-compose.yml` file to declare all your services, networks, and volumes.
*   **One Command to Rule Them All:** With `docker-compose up -d`, you can launch your entire application stack. With `docker-compose down`, you can tear it all down.

#### Example: WordPress + Database
With a simple `docker-compose.yml` file, you can define both the `wordpress` service and the `db` (database) service. Compose will automatically create a private network for them, allowing the WordPress container to find the database container simply by using its service name, `db`.

---
