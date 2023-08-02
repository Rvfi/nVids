import discord
import os
import subprocess
from discord.ext import commands
from dotenv import load_dotenv
load_dotenv()  
intents = discord.Intents.default()
intents.message_content = True  
bot = commands.Bot(command_prefix="!", intents=intents)


@bot.event
async def on_ready():
    print(f'We have logged in as {bot.user}')

@bot.event
async def on_message(message):
    if message.author == bot.user:
        return

    if message.content.startswith('!process') and message.attachments:
        print("Processing command received.")
        async with message.channel.typing():
            for attachment in message.attachments:
                print(f"Downloading attachment: {attachment.filename}")
                await attachment.save(attachment.filename)
                
                # Execute the script
                cmd = f"./aqvm.sh {attachment.filename} LogoMarkWhite.png InterV.var.ttf"
                print(f"Running command: {cmd}")
                process = subprocess.Popen(cmd, shell=True)
                process.wait()

                # Sends the output video back into the chat
                print("Sending output video.")
                await message.channel.send(file=discord.File('output.mp4'))

                # Delete the files after processing
                print("Deleting files.")
                os.remove(attachment.filename)
                os.remove("output.mp4")


bot.run(os.getenv('TOKEN'))
