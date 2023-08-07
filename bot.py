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
                cmd = f"./aqvm.sh {attachment.filename} LogoMarkWhite.png --use-img-generation --dont-remove-files"
                print(f"Running command: {cmd}")
                process = subprocess.Popen(cmd, shell=True, env={"OPENAI_API_KEY": os.getenv('OPENAI_API_KEY')})
                process.wait()

                # Sends the output video back into the chat
                print("Sending output video.")
                await message.channel.send(file=discord.File('output.mp4'))

                # If SEND_ALBUMS_ARTS_TO_CHANNEL_ID env is set, send the album art to the specified channel
                # Read text from text.srt file also
                if os.getenv('SEND_ALBUMS_ARTS_TO_CHANNEL_ID'):
                    channel = bot.get_channel(int(os.getenv('SEND_ALBUMS_ARTS_TO_CHANNEL_ID')))
                    text = open("text.srt", "r").read()
                    await channel.send(text, file=discord.File('album_art.png'))

                # Delete the files after processing
                print("Deleting files.")
                os.remove(attachment.filename)
                os.remove("output.mp4")

                # Since we told aqvm.sh not to remove the files, we have to do it manually
                filesToRemove = ["lufs.txt", "peak.txt", "text.srt", "album_art.png"]
                for file in filesToRemove:
                    os.remove(file)

bot.run(os.getenv('TOKEN'))
