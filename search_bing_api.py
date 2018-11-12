from requests import exceptions
import argparse
import requests
import cv2
import os

# construct the argument parser nd parser argument
ap = argparse.ArgumentParser()
ap.add_argument("-q", "--query", required=True, help="search query to search Bing Image API for")