from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_chroma import Chroma
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_openai import OpenAIEmbeddings
import chainlit as cl
import os


load_dotenv(override=True)

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
MODEL = "gpt-4.1-nano"
DB_NAME = "vector_db"

# Set up the key LangChain objects: retriever and llm.
embeddings = OpenAIEmbeddings(api_key=OPENAI_API_KEY, model="text-embedding-3-small")
vectorstore = Chroma(persist_directory=DB_NAME, embedding_function=embeddings)
retriever = vectorstore.as_retriever()
llm = ChatOpenAI(temperature=0, model_name=MODEL)

SYSTEM_PROMPT_TEMPLATE = """
You are a helpful, concise assistant for a software project.
Answer questions using the provided context when it is relevant.
If the context does not contain the answer, just say you don't know.
Prioritize clarity.
Context:
{context}
"""


def build_source_overview(docs):
    """Return readable labels and side panels for each retrieved chunk."""
    source_labels = []
    source_elements = []
    seen_labels = set()

    for doc in docs:
        metadata = doc.metadata or {}
        base_name = metadata.get("doc_name") or os.path.basename(metadata.get("source", "Document"))
        chunk_index = metadata.get("chunk_index")
        chunk_total = metadata.get("chunk_total")

        if chunk_index and chunk_total:
            label = f"{base_name} (section {chunk_index}/{chunk_total})"
        else:
            label = base_name

        if label not in seen_labels:
            source_labels.append(label)
            seen_labels.add(label)

        source_elements.append(cl.Text(name=label, content=doc.page_content, display="side"))

    return source_labels, source_elements

@cl.on_message
async def on_message(message: cl.Message):
    question = message.content
    
    # Retrieve context
    docs = await cl.make_async(retriever.invoke)(question)
    context_from_docs = "\n\n".join(doc.page_content for doc in docs)
    
    system_prompt = SYSTEM_PROMPT_TEMPLATE.format(context=context_from_docs)
    
    # Generate response
    response = await llm.ainvoke([
        SystemMessage(content=system_prompt), 
        HumanMessage(content=question)
    ])

    source_labels, source_elements = build_source_overview(docs)
    sources_text = f"Sources: {', '.join(source_labels)}" if source_labels else "Sources: none"

    await cl.Message(
        content=f"{response.content}\n\n{sources_text}",
        elements=source_elements
    ).send()
