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


def get_proficiency_bonus(cr):
    if cr <= 4:
        return 2
    elif cr <= 8:
        return 3
    elif cr <= 12:
        return 4
    elif cr <= 16:
        return 5
    elif cr <= 20:
        return 6
    elif cr <= 24:
        return 7
    elif cr <= 28:
        return 8
    else:
        return 9


def get_xp(cr):
    xp_table = {
        0: 0,
        0.125: 25,
        0.25: 50,
        0.5: 100,
        1: 200,
        2: 450,
        3: 700,
        4: 1100,
        5: 1800,
        6: 2300,
        7: 2900,
        8: 3900,
        9: 5000,
        10: 5900,
        11: 7200,
        12: 8400,
        13: 10000,
        14: 11500,
        15: 13000,
        16: 15000,
        17: 18000,
        18: 20000,
        19: 22000,
        20: 25000,
        21: 33000,
        22: 41000,
        23: 50000,
        24: 62000,
        25: 75000,
        26: 90000,
        27: 105000,
        28: 120000,
        29: 135000,
        30: 155000,
    }
    return xp_table.get(float(cr), 0)


@app.route("/add", methods=["GET", "POST"])
def add_creature():
    if request.method == "POST":
        challenge_rating = float(request.form["challenge_rating"])
        creature_data = {
            "name": request.form["name"],
            "index": request.form["name"].lower().replace(" ", "_"),
            "desc": request.form["desc"],
            "salvage": request.form["salvage"],
            "lore": [
                entry for entry in request.form.getlist("lore[]") if entry.strip()
            ],
            "size": request.form["size"],
            "type": request.form["type"]
            + (f" ({request.form['type_tag']})" if request.form["type_tag"] else ""),
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
                k: v
                for k, v in {
                    "walk": request.form["speed_walk"],
                    "fly": request.form["speed_fly"],
                    "swim": request.form["speed_swim"],
                    "climb": request.form["speed_climb"],
                    "burrow": request.form["speed_burrow"],
                }.items()
                if v
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
            "challenge_rating": challenge_rating,
            "proficiency_bonus": get_proficiency_bonus(challenge_rating),
            "xp": get_xp(challenge_rating),
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
