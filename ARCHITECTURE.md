# Seahorse Architecture

Seahorse is a visual framework for building and running Apache Spark workflows. This document summarizes runtime components, data flows, and key configuration based on the repository structure.

## High-level Diagram

```mermaid
flowchart LR
  subgraph Client
    UI[AngularJS SPA\n`frontend/`]
  end

  subgraph Edge
    RP[Node.js Reverse Proxy\n`proxy/`]
  end

  UI <-- HTTP/WebSockets --> RP

  subgraph Backend (Scala / sbt multi-project)
    WM[Workflow Manager\n`workflowmanager/`]
    SM[Session Manager\n`sessionmanager/`]
    DSM[Datasource Manager\n`datasourcemanager/`]
    LS[Library Service\n`libraryservice/`]
    SCH[Scheduling Manager\n`schedulingmanager/`]
  end

  RP <-- REST --> WM
  RP <-- REST --> SM
  RP <-- REST --> DSM
  RP <-- REST --> LS
  RP <-- REST --> SCH

  subgraph Execution Plane
    WE[Workflow Executor (Spark)\n`seahorse-workflow-executor/`]
    NB[Notebook Server\n`remote_notebook/`]
  end

  SM <-- AMQP (RabbitMQ) --> WE
  WE <-- HTTP --> WM
  WE <-- HTTP --> DSM
  WE --> NB

  subgraph Infra
    MQ[(RabbitMQ)]
    DB[(H2 DB)]
    FS[(Local FS: logs/artifacts)]
  end

  SM <-- 5672 AMQP --> MQ
  WE <-- 5672 AMQP --> MQ
  SM <-- JDBC --> DB
  WE --> FS
  SM --> FS
```

## Components

- **Frontend UI (`frontend/`)**
  - AngularJS 1.5 SPA built with Webpack 1. Serves the visual workflow editor, datasources, and reports.
  - Notable deps: `sockjs-client`, `stompjs`, `jsplumb`, `angular-ui-router`. See `frontend/package.json`.

- **Reverse Proxy (`proxy/`)**
  - Node.js Express app that serves the SPA and proxies REST to backend services. Supports sessions/Passport-based auth.
  - See `proxy/package.json` and scripts `startDev`/`start`.

- **Backend Services (Scala)**
  - Multi-project defined in `build.sbt`:
    - `workflowmanager/`: workflow CRUD/graph/reporting.
    - `sessionmanager/`: session lifecycle, executor orchestration, MQ integration.
    - `datasourcemanager/`: datasource definitions and IO endpoints.
    - `libraryservice/`: operation/library metadata.
    - `schedulingmanager/`: scheduled workflow runs; depends on WM/SM.
  - Shared utilities in `backendcommons/`.

- **Workflow Executor (`seahorse-workflow-executor/`)**
  - Spark-based executor with modules: `api`, `commons`, `deeplang`, `graph`, `reportlib`, `workflowjson`, `workflowexecutor`, `workflowexecutormqprotocol`.
  - Communicates with SM via RabbitMQ and with WM/DSM via HTTP.

- **Remote Notebook (`remote_notebook/`)**
  - Python services for Jupyter kernel management and socket forwarding used during interactive execution.

## Data Flows

- **Authoring**: UI → Proxy → Workflow Manager for workflow CRUD/graph operations. Live updates over SockJS/STOMP.
- **Run Workflow**: UI → Proxy → Session Manager. SM spawns Workflow Executor (Spark) with configured paths and MQ creds. Executor sends heartbeats/status via RabbitMQ and interacts with WM/DSM.
- **Notebooks**: Executor coordinates with `remote_notebook` for kernels/streams.

## Ports & Configuration

- **Session Manager (`sessionmanager/src/main/resources/application.conf`)**
  - HTTP: `0.0.0.0:9082` (override via `SM_HOST`/`SM_PORT`).
  - MQ: `MQ_HOST`/`MQ_PORT` (default `localhost:5672`), `MQ_USER`/`MQ_PASS`.
  - DB: `jdbc:h2:tcp://database:1521/sessionmanager` (override `JDBC_URL`).
  - Executor parameters (`session-executor.parameters`):
    - Workflow Manager: default `http://localhost:9080` (`SX_PARAM_WM_*`).
    - Notebook: default `127.0.0.1:60105` (`NOTEBOOK_SERVER_ADDRESS`).
    - Datasource Server: default `http://127.0.0.1:60108/datasourcemanager/v1/`.
    - Spark logs dir: `/tmp/deepsense/seahorse/spark-applications-logs`.

- **RabbitMQ**
  - Used by SM and WE via `workflowexecutormqprotocol` (`seahorse-workflow-executor/.../rabbitmq/*.scala`) and SM MQ module (`sessionmanager/.../mq`).

## Build & Run

- Build all Docker images and compose file: `./build/build_all.sh` (see `README.md`).
- Dev:
  - Frontend: `cd frontend && npm run serve`.
  - Proxy: `cd proxy && npm run startDev`.
  - Backend: `sbt` per module; run scalastyle/tests as in `README.md`.

## Repository Map

- `frontend/` AngularJS SPA
- `proxy/` Node.js reverse proxy
- `workflowmanager/`, `sessionmanager/`, `datasourcemanager/`, `libraryservice/`, `schedulingmanager/` Scala services
- `backendcommons/` shared backend code
- `seahorse-workflow-executor/` Spark executor and protocol libs
- `remote_notebook/` notebook integration
- `deployment/` deployment scripts and MQ assets
