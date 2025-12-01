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

## Project Structure

-   `src/app.py`: Main application logic for the chat interface.
-   `src/document_loader.py`: Script to load and index documents.
-   `knowledge-base/`: Directory to store your Markdown documents.
-   `vector_db/`: Directory where the Chroma database is persisted.
