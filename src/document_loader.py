import glob
import os
from collections import defaultdict
from pathlib import Path
from langchain_openai import OpenAIEmbeddings
from langchain_community.document_loaders import DirectoryLoader, TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_chroma import Chroma
from dotenv import load_dotenv

load_dotenv(override=True)
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
DB_NAME = "vector_db"

# Load the documents.
folders = glob.glob("knowledge-base/*")
documents = []
for folder in folders:
    doc_type = os.path.basename(folder)
    loader = DirectoryLoader(folder, glob="**/*.md", loader_cls=TextLoader, loader_kwargs={'encoding': 'utf-8'})
    folder_docs = loader.load()
    for doc in folder_docs:
        doc.metadata["doc_type"] = doc_type
        documents.append(doc)

print(f"Loaded {len(documents)} documents")

# Divide into chunks
text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=100)
chunks = text_splitter.split_documents(documents)

# Annotate chunks so we can expose the exact section to users later on.
chunks_by_source = defaultdict(list)
for chunk in chunks:
    source_path = chunk.metadata.get("source")
    doc_name = Path(source_path).name if source_path else chunk.metadata.get("doc_type", "Document")
    chunk.metadata.setdefault("doc_name", doc_name)
    chunks_by_source[source_path or doc_name].append(chunk)

for chunk_group in chunks_by_source.values():
    total_sections = len(chunk_group)
    for index, chunk in enumerate(chunk_group, start=1):
        chunk.metadata["chunk_index"] = index
        chunk.metadata["chunk_total"] = total_sections

# Create embeddings and vectorstore
embeddings = OpenAIEmbeddings(api_key=OPENAI_API_KEY, model="text-embedding-3-small")
vectorstore = Chroma.from_documents(documents=chunks, embedding=embeddings, persist_directory=DB_NAME)
print(f"Vectorstore created with {vectorstore._collection.count()} embeddings")