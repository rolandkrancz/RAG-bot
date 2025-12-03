# Simple RAG Chatbot

This is a simple Retrieval-Augmented Generation (RAG) chatbot built with [Chainlit](https://github.com/Chainlit/chainlit), [LangChain](https://github.com/langchain-ai/langchain), and [ChromaDB](https://github.com/chroma-core/chroma). It allows you to chat with your documents stored in the `knowledge-base` directory.

## Features

-   **Document Ingestion**: Loads Markdown files from the `knowledge-base` directory.
-   **Vector Database**: Uses ChromaDB to store and retrieve document embeddings.
-   **Chat Interface**: Provides a user-friendly chat interface using Chainlit.
-   **AI Model**: Powered by OpenAI's GPT models.

## Prerequisites

-   Python 3.10 or higher
-   An OpenAI API Key

## Setup

1.  **Create a virtual environment:**

    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows use `venv\Scripts\activate`
    ```

2.  **Install dependencies:**

    ```bash
    pip install -r requirements.txt
    ```

3.  **Configure Environment Variables:**

    Create a `.env` file in the root directory and add your OpenAI API key:

    ```env
    OPENAI_API_KEY=your_openai_api_key_here
    ```

## Usage

1.  **Ingest Documents:**

    Run the document loader to process files in `knowledge-base/` and populate the vector database:

    ```bash
    python src/document_loader.py
    ```

2.  **Run the Chatbot:**

    Start the Chainlit application:

    ```bash
    chainlit run src/app.py -w
    ```

    The application will open in your browser at `http://localhost:8000`.

## Deployment

### Run with Docker

1. Build the container image (defaults to linux/amd64 for Azure compatibility):

    ```bash
    docker buildx build \
      --platform linux/amd64 \
      -t rag-bot:latest \
      .
    ```

2. Start the container, passing the same environment variables you use locally:

    ```bash
    docker run --rm -p 8000:8000 \
      -e OPENAI_API_KEY=$OPENAI_API_KEY \
      rag-bot:latest
    ```

    The chat UI remains available at `http://localhost:8000`.

### Azure Container Apps via Terraform

Use the Terraform configuration under `terraform/` to deploy the image to Azure Container Apps (full details live in `terraform/README.md`).

1. **Prerequisites**: Azure CLI logged in to the right subscription, Terraform 1.0+, and a published container image (public or private registry such as GHCR).
2. **Configure Terraform**:

    ```bash
    cd terraform
    cp terraform.tfvars.example terraform.tfvars
    ```

    Update `terraform.tfvars` with:

    - `container_image`: full image reference (e.g., `ghcr.io/<owner>/rag-bot:latest`).
    - `container_port`: change only if the app listens on another port.
    - `openai_api_key` and any extra `environment_variables` your deployment needs.
    - `registry_*` credentials when pulling from a private registry.

3. **Deploy**:

    ```bash
    terraform init
    terraform plan
    terraform apply
    terraform output container_app_url
    ```

    Visit the printed URL to use the hosted chatbot.

4. **Update or tear down**: Re-run `terraform apply -var="container_image=<new ref>"` after pushing an updated image, or `terraform destroy` to remove the sandbox. 

## Project Structure

-   `src/app.py`: Main application logic for the chat interface.
-   `src/document_loader.py`: Script to load and index documents.
-   `knowledge-base/`: Directory to store your Markdown documents.
-   `vector_db/`: Directory where the Chroma database is persisted.
-   `requirements.txt`: Python dependencies for the app.
-   `Dockerfile`: Multi-stage image build for running under Docker or Azure.
-   `chainlit.md`: Chainlit UI configuration (sidebar copy, theme tweaks).
-   `terraform/`: Terraform IaC that provisions Azure Container Apps.
-   `rag-venv/`: Optional committed virtual environment snapshot.
