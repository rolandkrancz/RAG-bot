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
    
    await cl.Message(content=response.content).send()
