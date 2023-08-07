FROM python:3.10.8-slim

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get install -y ffmpeg
RUN apt-get install -y fontconfig
RUN apt-get install -y curl

COPY InterV.var.ttf /usr/local/share/fonts/InterV.var.ttf
RUN fc-cache -v

CMD ["python", "bot.py"]