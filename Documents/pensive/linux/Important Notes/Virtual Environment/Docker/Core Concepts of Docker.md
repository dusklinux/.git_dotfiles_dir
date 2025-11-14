The "What" - Core Concepts of Docker

### The Big Idea: Standardized Shipping Containers

Imagine global shipping before the modern shipping container. Goods were packed in random barrels, sacks, and crates. It was slow and inefficient. The standardized container changed everything. It doesn't matter what's inside—bananas or car parts—the container can be moved by any standard crane, truck, or ship.

**Docker applies this same idea to software.**

A Docker container is a standard package for your application. It bundles the application code with *all* its dependencies (libraries, tools, settings) into a single, runnable unit. This container can then be run on any computer with Docker installed, and it will work identically.

### The Docker Lexicon: The Four Key Terms

To understand Docker, you need to know these four terms. They build on each other.

| Term | Icon | Analogy | Description |
|---|---|---|---|
| **Dockerfile** | 📜 | The Recipe | A simple text file with step-by-step instructions on how to build your software package. You list a base to start from, commands to install software, and files to copy. |
| **Image** | 🖼️ | The Blueprint | A read-only template created from a `Dockerfile`. It's a snapshot of your application and all its dependencies, frozen in time. It's inert and doesn't run. |
| **Container** | 📦 | The Running Instance | A live, running instance of an image. If an image is the blueprint, the container is the actual house built from it. It's a lightweight, isolated process on your computer. |
| **Registry** | 🏢 | The Warehouse | A server where images are stored and shared. **Docker Hub** is the main public registry, like a GitHub for Docker images. You can also host your own private registry. |

The workflow is simple:
You write a `Dockerfile` ➡️ to build an `Image` ➡️ which you run as a `Container`. You `pull` and `push` images from a `Registry`.

---
