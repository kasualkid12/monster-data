from flask import Flask, render_template, request, redirect, url_for, flash
from pymongo import MongoClient
from bson.objectid import ObjectId
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.secret_key = os.urandom(24)

# MongoDB connection
client = MongoClient("mongodb://localhost:27017/")
db = client["grim_hallow"]
creatures = db["creatures"]


@app.route("/")
def index():
    all_creatures = list(creatures.find())
    return render_template("index.html", creatures=all_creatures)


@app.route("/add", methods=["GET", "POST"])
def add_creature():
    if request.method == "POST":
        creature_data = {
            "name": request.form["name"],
            "index": request.form["name"].lower().replace(" ", "_"),
            "desc": request.form["desc"],
            "salvage": request.form["salvage"],
            "lore": request.form["lore"].split("\n"),
            "size": request.form["size"],
            "type": request.form["type"],
            "alignment": request.form["alignment"],
            "armor_class": (
                int(request.form["armor_class"])
                if request.form["armor_class"]
                else None
            ),
            "hit_points": (
                int(request.form["hit_points"]) if request.form["hit_points"] else 0
            ),
            "hit_dice": request.form["hit_dice"],
            "speed": {
                "walk": request.form["speed_walk"],
                "fly": request.form["speed_fly"],
                "swim": request.form["speed_swim"],
            },
            "strength": (
                int(request.form["strength"]) if request.form["strength"] else 0
            ),
            "dexterity": (
                int(request.form["dexterity"]) if request.form["dexterity"] else 0
            ),
            "constitution": (
                int(request.form["constitution"]) if request.form["constitution"] else 0
            ),
            "intelligence": (
                int(request.form["intelligence"]) if request.form["intelligence"] else 0
            ),
            "wisdom": int(request.form["wisdom"]) if request.form["wisdom"] else 0,
            "charisma": (
                int(request.form["charisma"]) if request.form["charisma"] else 0
            ),
            "senses": {
                "passive_perception": (
                    int(request.form["passive_perception"])
                    if request.form["passive_perception"]
                    else 0
                )
            },
            "languages": request.form["languages"],
            "challenge_rating": (
                float(request.form["challenge_rating"])
                if request.form["challenge_rating"]
                else 0
            ),
            "proficiency_bonus": (
                int(request.form["proficiency_bonus"])
                if request.form["proficiency_bonus"]
                else 0
            ),
            "xp": int(request.form["xp"]) if request.form["xp"] else 0,
        }

        creatures.insert_one(creature_data)
        flash("Creature added successfully!", "success")
        return redirect(url_for("index"))

    return render_template("add.html")


@app.route("/search")
def search():
    query = request.args.get("q", "")
    if query:
        results = list(
            creatures.find(
                {
                    "$or": [
                        {"name": {"$regex": query, "$options": "i"}},
                        {"type": {"$regex": query, "$options": "i"}},
                        {"desc": {"$regex": query, "$options": "i"}},
                    ]
                }
            )
        )
    else:
        results = []
    return render_template("search.html", creatures=results, query=query)


if __name__ == "__main__":
    app.run(debug=True)
