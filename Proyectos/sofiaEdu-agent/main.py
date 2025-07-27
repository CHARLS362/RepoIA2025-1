from browser_use.llm import ChatGoogle
from browser_use import Agent, BrowserSession
from dotenv import load_dotenv
import asyncio

load_dotenv()

browser_session = BrowserSession(
    executable_path="C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    user_data_dir="C:\\Users\\ASUS TUF\\browser_profiles\\agente_nuevo",
    viewport={'width': 800, 'height': 647},
)

llm = ChatGoogle(
    model="gemini-2.0-flash-exp",
    temperature=0.0,
)

async def main():
    agent = Agent(
        task="Navega a https://sofia-red.vercel.app/ y logeate con las credenciales de usuario: admin@gmail.com y contraseña: 123",
        llm=llm,
        browser_session=browser_session,
    )
    result = await agent.run()
    print(result)
