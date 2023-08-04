import discord
import os
import subprocess
from discord.ext import commands
from dotenv import load_dotenv
import yt_dlp  # Import the yt-dlp library

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

    if message.attachments:
        # Check if the attachment is not an audio file
        if not message.attachments[0].filename.endswith(('.wav', '.mp3', '.ogg', '.m4a')):
            return

        print("Processing command received.")
        async with message.channel.typing():
            for attachment in message.attachments:
                print(f"Downloading attachment: {attachment.filename}")
                await attachment.save(attachment.filename)
                
                # Execute the script
                cmd = f"./aqvm.sh {attachment.filename} LogoMarkWhite.png"
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

    # Check if the message is a link to an Instagram reel
    elif 'https://www.instagram.com/reel/' in message.content:
        print("Processing Instagram reel.")
        async with message.channel.typing():
            # Use yt-dlp to download the video
            with yt_dlp.YoutubeDL({'outtmpl': 'reel.mp4'}) as ydl:
                ydl.download([message.content])

            # Send the downloaded video back to the chat
            print("Sending Instagram reel.")
            await message.channel.send(file=discord.File('reel.mp4'))

            # Delete the video after sending it
            print("Deleting reel.")
            os.remove('reel.mp4')


bot.run(os.getenv('TOKEN'))
