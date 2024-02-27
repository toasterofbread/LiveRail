import argparse
import requests
from bs4 import BeautifulSoup as Soup
import json
import os
from urllib.parse import parse_qs

CACHE_FILE = "./timetable_cache.json"
cache = None

DEFAULT_HEADERS = {
	"User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:123.0) Gecko/20100101 Firefox/123.0"
}

TIMETABLE_URL_PREFIX = "/timetable/railway/line-station/"
TRAIN_URL_PREFIX = "/timetable/railway/train?"
STATION_URL_PREFIX = "/timetable/railway/station/"

class StationTimetableRef:
	def __init__(self, id: str, station_name: str, direction_name: str):
		self.id = id
		self.station_name = station_name
		self.direction_name = direction_name

	def encode(self):
		return {"name": self.station_name, "direction": self.direction_name}

	def __repr__(self) -> str:
		return f"StationTimetableRef(id={self.id}, station_name={self.station_name}, direction_name={self.direction_name})"

class TrainRef:
	def __init__(self, id: str, sf: str, type: str, destination: str):
		self.id = id
		self.sf = sf
		self.type = type
		self.destination = destination

	def encode(self):
		return {"type": self.type, "destination": self.destination}

	def __repr__(self) -> str:
		return f"TrainRef(id={self.id}, sf={self.sf}, type={self.type}, destination={self.destination})"

class TrainStopRef:
	def __init__(self, station: str, arr: str, dep: str):
		self.station = station
		self.dep = dep
		self.arr = arr

	def encode(self):
		return self.__dict__

	def __repr__(self) -> str:
		return f"TrainStopRef(station={self.station}, arr={self.arr}, dep={self.dep})"

def getRequest(url: str) -> str:
	global cache

	# Load cache on first run
	if cache is None:
		if os.path.exists(CACHE_FILE):
			f = open(CACHE_FILE, "r")
			cache = json.loads(f.read())
			f.close()
		else:
			cache = {}

	# Get cached value for url if present
	cached = cache.get(url)
	if cached is not None:
		print(f"Using cached {url}")
		return cached

	print(f"Getting remote {url}")

	# Get remote data at passed URL using DEFAULT_HEADERS
	result = requests.get(
		url,
		headers = DEFAULT_HEADERS
	)
	result.raise_for_status()

	# Decode result body and store in cache
	ret = result.content.decode()
	cache[url] = ret

	# Commit cache to file
	with open(CACHE_FILE, "w") as f:
		f.write(json.dumps(cache))

	# Return decoded result body
	return ret

def getLineTimetables(line_id: int) -> list[StationTimetableRef]:
	result = getRequest(f"https://ekitan.com/timetable/railway/line/{line_id}")
	soup = Soup(result, "html.parser")

	timetables = []

	for a in soup.find_all("a"):
		href = a.get("href")
		if href is None or not href.startswith(TIMETABLE_URL_PREFIX):
			continue

		id = href[len(TIMETABLE_URL_PREFIX):]
		station_name = a.parent.parent.parent.parent.find("dt").find("a").text
		direction_name = a.text

		timetables.append(StationTimetableRef(id, station_name, direction_name))

	return timetables

def getTimetableTrains(timetable: StationTimetableRef) -> list[TrainRef]:
	result = getRequest(f"https://ekitan.com/timetable/railway/line-station/{timetable.id}")
	soup = Soup(result, "html.parser")

	trains = []

	for a in soup.find_all("a"):
		href = a.get("href")
		if href is None or not href.startswith(TRAIN_URL_PREFIX):
			continue

		params = parse_qs(href[len(TRAIN_URL_PREFIX):])
		id = params["tx"][0]
		sf = params["sf"][0]

		type = a.parent.get("data-tr-type")
		destination = a.parent.get("data-dest")

		trains.append(TrainRef(id, sf, type, destination))

	return trains

def getTrainStops(train: TrainRef) -> list[TrainStopRef]:
	result = getRequest(f"https://ekitan.com/timetable/railway/train?tx={train.id}&sf={train.sf}")
	soup = Soup(result, "html.parser")

	stops = []

	for a in soup.find_all("a"):
		href = a.get("href")
		if href is None or not href.startswith(STATION_URL_PREFIX):
			continue

		station_name = a.text

		times = a.parent.parent.parent.find("td").text.strip().replace("\t", "").split(" ")
		arrival = None
		departure = None

		for time in times:
			if time.endswith("着"):
				arrival = time[:-1]
			elif time.endswith("発"):
				departure = time[:-1]

		stops.append(TrainStopRef(station_name, arrival, departure))

	return stops

def getAllLineTrainStops(line_id: int):
	trains = []

	for timetable in getLineTimetables(line_id):
		for train in getTimetableTrains(timetable):

			already_added = False
			for other_train in trains:
				if train.id == other_train["train"].id:
					already_added = True
					break

			if already_added:
				continue

			trains.append({"train": train})

	for train in trains:
		train["stops"] = getTrainStops(train["train"])

	return trains

def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("line_id", type = int)
	args = parser.parse_args()

	trains = getAllLineTrainStops(args.line_id)
	data = json.dumps(trains, default = lambda x: x.encode())

	with open(f"{args.line_id}.json", "w") as f:
		f.write(data)

	if cache is not None:
		with open(CACHE_FILE, "w") as f:
			f.write(json.dumps(cache))

if __name__ == "__main__":
	main()
